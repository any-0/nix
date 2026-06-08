import { mkdir, readFile, writeFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Context, Model, SimpleStreamOptions, ThinkingLevel } from "@earendil-works/pi-ai";

const SETTINGS_KEY = "pi-codex-fast";
const STATUS_KEY = "fast";

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function agentDir(): string {
	return process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
}

function globalSettingsPath(): string {
	return join(agentDir(), "settings.json");
}

async function readJsonFile(path: string): Promise<Record<string, unknown>> {
	try {
		const parsed = JSON.parse(await readFile(path, "utf8"));
		return isRecord(parsed) ? parsed : {};
	} catch (error) {
		if (isRecord(error) && error.code === "ENOENT") return {};
		throw error;
	}
}

function settingEnabled(settings: Record<string, unknown>): boolean | undefined {
	const value = settings[SETTINGS_KEY];
	return isRecord(value) && typeof value.enabled === "boolean" ? value.enabled : undefined;
}

async function loadFastMode(): Promise<boolean> {
	return settingEnabled(await readJsonFile(globalSettingsPath())) ?? false;
}

async function saveFastMode(enabled: boolean): Promise<void> {
	const path = globalSettingsPath();
	const settings = await readJsonFile(path);
	const previous = settings[SETTINGS_KEY];
	settings[SETTINGS_KEY] = { ...(isRecord(previous) ? previous : {}), enabled };
	await mkdir(dirname(path), { recursive: true });
	await writeFile(path, `${JSON.stringify(settings, null, 2)}\n`);
}

function supportsFastMode(ctx: ExtensionContext): boolean {
	return ctx.model?.provider === "openai" || ctx.model?.provider === "openai-codex";
}

function formatTokens(count: number): string {
	if (count < 1000) return count.toString();
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
	return `${Math.round(count / 1000000)}M`;
}

function compactPath(cwd: string): string {
	const home = process.env.HOME || process.env.USERPROFILE;
	return home && (cwd === home || cwd.startsWith(`${home}/`)) ? `~${cwd.slice(home.length)}` : cwd;
}

function sanitizedLine(text: string): string {
	return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

function visibleWidth(text: string): number {
	return text.replace(/\x1b\[[0-9;]*m/g, "").length;
}

function truncateToWidth(text: string, width: number, ellipsis = "…"): string {
	if (visibleWidth(text) <= width) return text;
	if (width <= visibleWidth(ellipsis)) return ellipsis.slice(0, Math.max(0, width));
	return `${text.slice(0, Math.max(0, width - visibleWidth(ellipsis)))}${ellipsis}`;
}

function mapReasoningEffort(model: Model<any>, reasoning: ThinkingLevel | undefined): string | undefined {
	if (!reasoning) return undefined;
	const mapped = model.thinkingLevelMap?.[reasoning] ?? reasoning;
	return mapped === null ? undefined : mapped;
}

function withFastOptions(model: Model<any>, options: SimpleStreamOptions | undefined, enabled: boolean) {
	return {
		...options,
		reasoningEffort: mapReasoningEffort(model, options?.reasoning),
		serviceTier: enabled && supportsFastMode({ model } as ExtensionContext) ? "priority" : undefined,
	};
}

function setCodexOriginator(headers: unknown): void {
	if (!headers) return;
	if (headers instanceof Headers) {
		headers.set("originator", "codex_cli_rs");
		return;
	}
	if (isRecord(headers)) {
		headers.originator = "codex_cli_rs";
	}
}

function installCodexOriginatorPatch(isEnabled: () => boolean): void {
	const key = Symbol.for("pi-codex-fast.originatorPatch");
	const state = globalThis as typeof globalThis & { [key]?: boolean };
	if (state[key]) return;
	state[key] = true;

	const originalHeadersSet = Headers.prototype.set;
	Headers.prototype.set = function set(name: string, value: string): void {
		if (isEnabled() && name.toLowerCase() === "originator" && value === "pi") {
			return originalHeadersSet.call(this, name, "codex_cli_rs");
		}
		return originalHeadersSet.call(this, name, value);
	};

	const originalFetch = globalThis.fetch;
	globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
		const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
		if (isEnabled() && url.includes("chatgpt.com") && url.includes("/codex/responses")) {
			if (init) setCodexOriginator(init.headers);
			else init = { headers: { originator: "codex_cli_rs" } };
		}
		return originalFetch(input, init);
	}) as typeof fetch;

	const OriginalWebSocket = globalThis.WebSocket;
	if (typeof OriginalWebSocket !== "function") return;

	class CodexFastWebSocket extends OriginalWebSocket {
		constructor(url: string | URL, options?: string | string[] | Record<string, unknown>) {
			if (isEnabled() && url.toString().includes("chatgpt.com") && isRecord(options)) {
				setCodexOriginator(options.headers);
			}
			super(url, options as any);
		}
	}
	globalThis.WebSocket = CodexFastWebSocket as typeof WebSocket;
}

async function importPiAiProvider(file: string): Promise<Record<string, any>> {
	let piMain: string | undefined;
	try {
		const resolved = import.meta.resolve?.("@earendil-works/pi-coding-agent");
		piMain = resolved?.startsWith("file:") ? new URL(resolved).pathname : resolved;
	} catch {
		// fall through to require.resolve fallback
	}
	if (!piMain) {
		try {
			const require = createRequire(process.argv[1] ?? import.meta.url);
			piMain = require.resolve("@earendil-works/pi-coding-agent");
		} catch {
			piMain = "/home/orli_ju/.local/share/npm-global/lib/node_modules/@earendil-works/pi-coding-agent/dist/index.js";
		}
	}
	const piRoot = dirname(dirname(piMain));
	const providerPath = join(piRoot, "node_modules", "@earendil-works", "pi-ai", "dist", "providers", file);
	return import(pathToFileURL(providerPath).href);
}

export default async function fastExtension(pi: ExtensionAPI): Promise<void> {
	let enabled = false;
	let currentModel: Model<any> | undefined;
	const isCodexFastActive = () =>
		enabled && currentModel?.provider === "openai-codex" && supportsFastMode({ model: currentModel } as ExtensionContext);
	installCodexOriginatorPatch(isCodexFastActive);
	const { streamOpenAIResponses } = await importPiAiProvider("openai-responses.js");
	const { streamOpenAICodexResponses } = await importPiAiProvider("openai-codex-responses.js");

	// Mutating `before_provider_request` only changes the JSON payload. The provider's
	// internal `options.serviceTier` remains unset, so Codex pricing/response-tier
	// resolution still treats the call as default. Override the OpenAI response
	// streamers so fast mode is represented as a real provider option.
	pi.registerProvider("openai", {
		api: "openai-responses",
		streamSimple: (model: Model<any>, context: Context, options?: SimpleStreamOptions) =>
			streamOpenAIResponses(model, context, withFastOptions(model, options, enabled)),
	});
	pi.registerProvider("openai-codex", {
		api: "openai-codex-responses",
		streamSimple: (model: Model<any>, context: Context, options?: SimpleStreamOptions) =>
			streamOpenAICodexResponses(model, context, withFastOptions(model, options, enabled)),
	});

	function updateFooter(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;

		// Clear status left behind by older versions of this extension.
		ctx.ui.setStatus(STATUS_KEY, undefined);

		if (!enabled) {
			ctx.ui.setFooter(undefined);
			return;
		}

		ctx.ui.setFooter((tui, theme, footerData) => ({
			dispose: footerData.onBranchChange(() => tui.requestRender()),
			invalidate() {},
			render(width: number): string[] {
				let input = 0;
				let output = 0;
				let cacheRead = 0;
				let cacheWrite = 0;
				let cost = 0;

				for (const entry of ctx.sessionManager.getEntries()) {
					if (entry.type !== "message" || entry.message.role !== "assistant") continue;
					const usage = entry.message.usage;
					input += usage.input;
					output += usage.output;
					cacheRead += usage.cacheRead;
					cacheWrite += usage.cacheWrite;
					cost += usage.cost.total;
				}

				let pwd = compactPath(ctx.sessionManager.getCwd());
				const branch = footerData.getGitBranch();
				const sessionName = ctx.sessionManager.getSessionName();
				if (branch) pwd += ` (${branch})`;
				if (sessionName) pwd += ` • ${sessionName}`;

				const stats: string[] = [];
				if (input) stats.push(`↑${formatTokens(input)}`);
				if (output) stats.push(`↓${formatTokens(output)}`);
				if (cacheRead) stats.push(`R${formatTokens(cacheRead)}`);
				if (cacheWrite) stats.push(`W${formatTokens(cacheWrite)}`);
				if (cost || (ctx.model && ctx.modelRegistry.isUsingOAuth(ctx.model))) {
					stats.push(`$${cost.toFixed(3)}${ctx.model && ctx.modelRegistry.isUsingOAuth(ctx.model) ? " (sub)" : ""}`);
				}

				const context = ctx.getContextUsage();
				const contextWindow = context?.contextWindow ?? ctx.model?.contextWindow ?? 0;
				const percent = context?.percent;
				stats.push(percent === null || percent === undefined ? `?/${formatTokens(contextWindow)}` : `${percent.toFixed(1)}%/${formatTokens(contextWindow)}`);

				let left = stats.join(" ");
				if (visibleWidth(left) > width) left = truncateToWidth(left, width, "...");

				const modelName = ctx.model?.id ?? "no-model";
				let model = modelName;
				if (ctx.model?.reasoning) {
					const thinking = pi.getThinkingLevel();
					model += thinking === "off" ? " • thinking off" : ` • ${thinking}`;
				}
				model += supportsFastMode(ctx) ? " • fast" : " • fast inactive";

				let right = ctx.model && footerData.getAvailableProviderCount() > 1 ? `(${ctx.model.provider}) ${model}` : model;
				const minPadding = 2;
				if (visibleWidth(left) + minPadding + visibleWidth(right) > width) right = model;

				const available = width - visibleWidth(left) - minPadding;
				if (visibleWidth(right) > available) right = truncateToWidth(right, Math.max(0, available), "");
				const line = left + " ".repeat(Math.max(minPadding, width - visibleWidth(left) - visibleWidth(right))) + right;

				const lines = [
					theme.fg("dim", truncateToWidth(pwd, width, "...")),
					theme.fg("dim", left) + theme.fg("dim", line.slice(left.length)),
				];

				const statuses = Array.from(footerData.getExtensionStatuses().entries())
					.filter(([key]) => key !== STATUS_KEY)
					.sort(([a], [b]) => a.localeCompare(b))
					.map(([, text]) => sanitizedLine(text));
				if (statuses.length) lines.push(truncateToWidth(statuses.join(" "), width, theme.fg("dim", "...")));

				return lines;
			},
		}));
	}

	function notify(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		ctx.ui.notify(enabled ? "Fast mode enabled." : "Fast mode disabled.", "info");
	}

	async function setFastMode(next: boolean, ctx: ExtensionContext): Promise<void> {
		enabled = next;
		currentModel = ctx.model;
		updateFooter(ctx);
		await saveFastMode(enabled);
	}

	pi.registerFlag("fast", {
		description: "Enable OpenAI/OpenAI Codex priority service tier for this run",
		type: "boolean",
		default: false,
	});

	pi.registerCommand("fast", {
		description: "Toggle OpenAI/OpenAI Codex priority service tier",
		handler: async (_args, ctx) => {
			await setFastMode(!enabled, ctx);
			notify(ctx);
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		currentModel = ctx.model;
		try {
			enabled = pi.getFlag("fast") === true || await loadFastMode();
		} catch (error) {
			if (ctx.hasUI) ctx.ui.notify(`fast: failed to load settings: ${error instanceof Error ? error.message : String(error)}`, "warning");
		}
		updateFooter(ctx);
	});

	pi.on("model_select", (_event, ctx) => {
		currentModel = ctx.model;
		updateFooter(ctx);
	});

	pi.on("before_provider_request", (event, ctx) => {
		currentModel = ctx.model;
		if (!enabled || !supportsFastMode(ctx) || !isRecord(event.payload) || "service_tier" in event.payload) return;
		return { ...event.payload, service_tier: "priority" };
	});
}
