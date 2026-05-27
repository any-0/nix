import type { ExtensionAPI, BashOperations } from "@earendil-works/pi-coding-agent";
import { createBashTool, isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { spawn, spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, realpathSync, unlinkSync, writeFileSync, appendFileSync, readdirSync, statSync, closeSync, openSync } from "node:fs";
import os from "node:os";
import path from "node:path";

// File Guard: portable, scope-relative read/write deny rules for pi.
//
// Policy locations:
//   ~/.pi/agent/file-guard.json          trusted user policy
//   <ancestor>/.pi/file-guard.json       workspace policies from $HOME down to cwd
//
// Relative patterns in a workspace policy are relative to the directory containing
// the .pi directory. Example: ~/repo/.pi/file-guard.json with denyRead [".env"]
// blocks ~/repo/.env even when pi is started in ~/repo/src.

type Mode = "off" | "warn" | "prompt" | "strict";
type RuleKind = "denyRead" | "allowRead" | "denyWrite" | "allowWrite";

type PolicyConfig = {
	enabled?: boolean;
	mode?: Mode;
	denyRead?: string[];
	allowRead?: string[];
	denyWrite?: string[];
	allowWrite?: string[];
};

type Policy = {
	id: string;
	path: string;
	baseDir: string;
	trusted: boolean;
	config: PolicyConfig;
};

type Rule = {
	kind: RuleKind;
	pattern: string;
	policy: Policy;
};

type EffectivePolicy = {
	mode: Mode;
	policies: Policy[];
	rules: Rule[];
};

const HOME = path.resolve(os.homedir());
const AGENT_DIR = path.join(HOME, ".pi", "agent");
const GLOBAL_POLICY_PATH = path.join(AGENT_DIR, "file-guard.json");
const LOG_PATH = path.join(AGENT_DIR, "file-guard.log");
const MODE_RANK: Record<Mode, number> = { off: 0, warn: 1, prompt: 2, strict: 3 };
const DEFAULT_MODE: Mode = "strict";

function log(line: string) {
	try {
		mkdirSync(AGENT_DIR, { recursive: true });
		appendFileSync(LOG_PATH, `[${new Date().toISOString()}] ${line}\n`);
	} catch {
		// Logging must never break tool execution.
	}
}

function isMode(value: unknown): value is Mode {
	return value === "off" || value === "warn" || value === "prompt" || value === "strict";
}

function asStringArray(value: unknown): string[] {
	return Array.isArray(value) ? value.filter((v): v is string => typeof v === "string" && v.trim().length > 0) : [];
}

function sanitizeConfig(raw: unknown): PolicyConfig {
	const obj = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
	return {
		enabled: typeof obj.enabled === "boolean" ? obj.enabled : undefined,
		mode: isMode(obj.mode) ? obj.mode : undefined,
		denyRead: asStringArray(obj.denyRead),
		allowRead: asStringArray(obj.allowRead),
		denyWrite: asStringArray(obj.denyWrite),
		allowWrite: asStringArray(obj.allowWrite),
	};
}

function readPolicyFile(policyPath: string, baseDir: string, trusted: boolean): Policy | undefined {
	if (!existsSync(policyPath)) return undefined;
	try {
		const config = sanitizeConfig(JSON.parse(readFileSync(policyPath, "utf-8")));
		if (config.enabled === false) return undefined;
		return { id: policyPath, path: policyPath, baseDir, trusted, config };
	} catch (err) {
		log(`CONFIG_ERROR ${policyPath}: ${err instanceof Error ? err.message : String(err)}`);
		return undefined;
	}
}

function isInside(parent: string, child: string): boolean {
	const rel = path.relative(parent, child);
	return rel === "" || (!rel.startsWith("..") && !path.isAbsolute(rel));
}

function ancestorDirsFromHome(cwd: string): string[] {
	const abs = path.resolve(cwd);
	if (!isInside(HOME, abs)) return [abs];

	const rel = path.relative(HOME, abs);
	const parts = rel ? rel.split(path.sep).filter(Boolean) : [];
	const dirs = [HOME];
	let cur = HOME;
	for (const part of parts) {
		cur = path.join(cur, part);
		dirs.push(cur);
	}
	return dirs;
}

function loadEffectivePolicy(cwd: string): EffectivePolicy {
	const policies: Policy[] = [];
	const globalPolicy = readPolicyFile(GLOBAL_POLICY_PATH, HOME, true);
	if (globalPolicy) policies.push(globalPolicy);

	for (const dir of ancestorDirsFromHome(cwd)) {
		const p = readPolicyFile(path.join(dir, ".pi", "file-guard.json"), dir, false);
		if (p) policies.push(p);
	}

	// Only the trusted user policy can weaken the default mode. Workspace
	// policies may make the mode stricter but cannot turn the guard down/off.
	let mode: Mode = globalPolicy?.config.mode ?? DEFAULT_MODE;
	for (const policy of policies) {
		const requested = policy.config.mode;
		if (!requested) continue;
		if (policy.trusted || MODE_RANK[requested] > MODE_RANK[mode]) mode = requested;
	}

	const rules: Rule[] = [];
	for (const policy of policies) {
		for (const kind of ["denyRead", "allowRead", "denyWrite", "allowWrite"] as RuleKind[]) {
			for (const pattern of policy.config[kind] ?? []) rules.push({ kind, pattern, policy });
		}
	}

	return { mode, policies, rules };
}

function normalize(p: string): string {
	return path.resolve(p).split(path.sep).join("/");
}

function hasGlob(pattern: string): boolean {
	return /[*?[]/.test(pattern);
}

function expandHome(pattern: string): string {
	if (pattern === "~") return HOME;
	if (pattern.startsWith("~/")) return path.join(HOME, pattern.slice(2));
	return pattern;
}

function absolutePattern(rule: Rule): string {
	const expanded = expandHome(rule.pattern);
	return path.isAbsolute(expanded) ? expanded : path.resolve(rule.policy.baseDir, expanded);
}

function realpathExistingPrefix(absPattern: string): string | undefined {
	const normalized = path.resolve(absPattern);
	const parts = normalized.split(path.sep).filter(Boolean);
	let prefix = path.isAbsolute(normalized) ? path.sep : "";
	let i = 0;
	for (; i < parts.length; i++) {
		if (/[\*?[]/.test(parts[i])) break;
		const next = path.join(prefix, parts[i]);
		if (!existsSync(next)) break;
		prefix = next;
	}
	try {
		const realPrefix = realpathSync.native(prefix);
		return path.join(realPrefix, ...parts.slice(i));
	} catch {
		return undefined;
	}
}

function globToRegexSource(glob: string): string {
	const s = glob.split(path.sep).join("/");
	let out = "^";
	for (let i = 0; i < s.length; ) {
		const ch = s[i];
		if (s.slice(i, i + 3) === "**/") {
			out += "(?:.*/)?";
			i += 3;
		} else if (ch === "*" && s[i + 1] === "*") {
			out += ".*";
			i += 2;
		} else if (ch === "*") {
			out += "[^/]*";
			i++;
		} else if (ch === "?") {
			out += "[^/]";
			i++;
		} else {
			out += ch.replace(/[|\\{}()[\]^$+?.]/g, "\\$&");
			i++;
		}
	}
	out += "$";
	return out;
}

function matchesAbsolutePattern(absPattern: string, absCandidate: string): boolean {
	const p = normalize(absPattern);
	const c = normalize(absCandidate);

	if (!hasGlob(p)) {
		return c === p || c.startsWith(`${p}/`);
	}

	return new RegExp(globToRegexSource(p)).test(c);
}

function matchingRules(effective: EffectivePolicy, kind: RuleKind, absCandidate: string): Rule[] {
	const matches: Rule[] = [];
	for (const rule of effective.rules) {
		if (rule.kind !== kind) continue;
		const abs = absolutePattern(rule);
		if (matchesAbsolutePattern(abs, absCandidate)) {
			matches.push(rule);
			continue;
		}
		const realPattern = realpathExistingPrefix(abs);
		if (realPattern && matchesAbsolutePattern(realPattern, absCandidate)) matches.push(rule);
	}
	return matches;
}

function candidatePaths(cwd: string, requestedPath: string): string[] {
	const abs = path.resolve(cwd, expandHome(requestedPath));
	const candidates = [abs];
	try {
		const real = realpathSync.native(abs);
		if (!candidates.includes(real)) candidates.push(real);
	} catch {
		// Non-existent paths are still checked lexically.
	}
	return candidates;
}

function shouldBlock(effective: EffectivePolicy, operation: "read" | "write", candidates: string[]) {
	const denyKind: RuleKind = operation === "read" ? "denyRead" : "denyWrite";
	const allowKind: RuleKind = operation === "read" ? "allowRead" : "allowWrite";

	for (const candidate of candidates) {
		for (const deny of matchingRules(effective, denyKind, candidate)) {
			// Allows only carve out denies from the same policy file. This prevents a
			// workspace policy from weakening the trusted user policy.
			const allowedBySamePolicy = matchingRules(effective, allowKind, candidate).some(
				(allow) => allow.policy.id === deny.policy.id,
			);
			if (!allowedBySamePolicy) return { block: true, rule: deny, path: candidate };
		}
	}
	return { block: false as const };
}

function displayPath(p: string): string {
	const abs = path.resolve(p);
	if (abs === HOME) return "~";
	if (isInside(HOME, abs)) return `~/${path.relative(HOME, abs).split(path.sep).join("/")}`;
	return abs;
}

function policyScope(policy: Policy): string {
	return policy.trusted ? "user" : `workspace ${displayPath(policy.baseDir)}`;
}

function formatRule(rule: Rule): string {
	return `${policyScope(rule.policy)}: ${rule.pattern}`;
}

async function handleBlockedTool(ctx: any, effective: EffectivePolicy, operation: "read" | "write", requestedPath: string, rule: Rule) {
	const msg = `${operation} blocked for ${requestedPath}; matched ${formatRule(rule)}`;
	log(`BLOCK ${operation} ${requestedPath} rule=${rule.policy.path}:${rule.pattern}`);

	if (effective.mode === "off") return undefined;
	if (effective.mode === "warn") {
		ctx.ui?.notify?.(`⚠️ File guard warning: ${msg}`, "warning");
		return undefined;
	}
	if (effective.mode === "prompt" && ctx.hasUI) {
		const choice = await ctx.ui.select(`File guard: ${msg}`, ["Keep blocked", "Allow once"]);
		if (choice === "Allow once") {
			log(`ALLOW_ONCE ${operation} ${requestedPath}`);
			return undefined;
		}
	}
	return { block: true, reason: `File guard: ${msg}` };
}

function shellEscape(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function gitRoot(cwd: string): string | undefined {
	const result = spawnSync("git", ["-C", cwd, "rev-parse", "--show-toplevel"], { encoding: "utf-8" });
	return result.status === 0 ? result.stdout.trim() : undefined;
}

function toStoredPattern(input: string, baseDir: string): string {
	if (input.startsWith("~/")) return input;
	if (hasGlob(input) && !path.isAbsolute(input)) return input;
	const abs = path.resolve(baseDir, expandHome(input));
	if (isInside(baseDir, abs)) return path.relative(baseDir, abs).split(path.sep).join("/") || ".";
	if (isInside(HOME, abs)) return `~/${path.relative(HOME, abs).split(path.sep).join("/")}`;
	return abs;
}

function readJsonConfig(file: string): PolicyConfig {
	if (!existsSync(file)) return {};
	return sanitizeConfig(JSON.parse(readFileSync(file, "utf-8")));
}

function writeJsonConfig(file: string, config: PolicyConfig) {
	mkdirSync(path.dirname(file), { recursive: true });
	writeFileSync(file, `${JSON.stringify(config, null, "\t")}\n`);
}

function addRule(file: string, kind: RuleKind, pattern: string) {
	const config = readJsonConfig(file);
	const arr = new Set([...(config[kind] ?? []), pattern]);
	config[kind] = [...arr].sort();
	writeJsonConfig(file, config);
}

function removeRule(file: string, kinds: RuleKind[], candidates: Set<string>): number {
	const config = readJsonConfig(file);
	let removed = 0;
	for (const kind of kinds) {
		const before = config[kind] ?? [];
		const after = before.filter((pattern) => !candidates.has(pattern) && !candidates.has(pattern.split(path.sep).join("/")));
		removed += before.length - after.length;
		config[kind] = after;
	}
	if (removed > 0) writeJsonConfig(file, config);
	return removed;
}

function removalCandidates(rawPattern: string, cwd: string, policy: Policy): Set<string> {
	const candidates = new Set<string>([rawPattern, rawPattern.split(path.sep).join("/")]);
	try {
		candidates.add(toStoredPattern(rawPattern, policy.baseDir));
	} catch {}
	try {
		const abs = path.resolve(cwd, expandHome(rawPattern));
		if (isInside(policy.baseDir, abs)) candidates.add(path.relative(policy.baseDir, abs).split(path.sep).join("/") || ".");
		if (isInside(HOME, abs)) candidates.add(`~/${path.relative(HOME, abs).split(path.sep).join("/")}`);
	} catch {}
	return candidates;
}

function parseRuleKinds(value: string | undefined): { kinds: RuleKind[]; consumed: boolean } {
	switch (value) {
		case "denyRead":
		case "allowRead":
		case "denyWrite":
		case "allowWrite":
			return { kinds: [value], consumed: true };
		case "deny":
			return { kinds: ["denyRead", "denyWrite"], consumed: true };
		case "allow":
			return { kinds: ["allowRead", "allowWrite"], consumed: true };
		case "read":
			return { kinds: ["denyRead", "allowRead"], consumed: true };
		case "write":
			return { kinds: ["denyWrite", "allowWrite"], consumed: true };
		default:
			return { kinds: ["denyRead", "allowRead", "denyWrite", "allowWrite"], consumed: false };
	}
}

function policyTargetForRule(cwd: string, rawPattern: string): { file: string; baseDir: string; stored: string } {
	const root = gitRoot(cwd) ?? cwd;
	const expanded = expandHome(rawPattern);
	const absoluteish = path.isAbsolute(expanded) || rawPattern.startsWith("~/");
	const abs = absoluteish ? path.resolve(expanded) : path.resolve(cwd, rawPattern);

	if (hasGlob(rawPattern) && !absoluteish) {
		return {
			file: path.join(root, ".pi", "file-guard.json"),
			baseDir: root,
			stored: rawPattern.split(path.sep).join("/"),
		};
	}

	if (isInside(root, abs)) {
		return {
			file: path.join(root, ".pi", "file-guard.json"),
			baseDir: root,
			stored: path.relative(root, abs).split(path.sep).join("/") || ".",
		};
	}

	return { file: GLOBAL_POLICY_PATH, baseDir: HOME, stored: toStoredPattern(rawPattern, HOME) };
}

function modeSummary(effective: EffectivePolicy): string {
	const denyRead = effective.rules.filter((r) => r.kind === "denyRead").length;
	const denyWrite = effective.rules.filter((r) => r.kind === "denyWrite").length;
	const sandbox = canUseMacSandbox() ? "mac sandbox on" : canUseLinuxSandbox() ? "bwrap on" : "sandbox unavailable";
	return `🔒 guard: ${effective.mode} · read ${denyRead} · write ${denyWrite} · ${sandbox}`;
}

function findExecutable(name: string): string | undefined {
	for (const dir of (process.env.PATH ?? "").split(path.delimiter)) {
		if (!dir) continue;
		const full = path.join(dir, name);
		if (existsSync(full)) return full;
	}
	return undefined;
}

function canUseMacSandbox(): boolean {
	return process.platform === "darwin" && existsSync("/usr/bin/sandbox-exec");
}

function linuxSandboxExecutable(): string | undefined {
	return process.platform === "linux" ? findExecutable("bwrap") : undefined;
}

function canUseLinuxSandbox(): boolean {
	return !!linuxSandboxExecutable();
}

function escapeSandboxString(value: string): string {
	return value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
}

function sandboxFiltersForRule(rule: Rule): string[] {
	const abs = absolutePattern(rule);
	const patterns = [abs];
	const real = realpathExistingPrefix(abs);
	if (real && real !== abs) patterns.push(real);

	const filters: string[] = [];
	for (const pattern of patterns) {
		const normalized = normalize(pattern);
		if (hasGlob(normalized)) {
			filters.push(`(regex #"${escapeSandboxString(globToRegexSource(normalized))}")`);
		} else {
			filters.push(`(literal "${escapeSandboxString(normalized)}")`);
			filters.push(`(subpath "${escapeSandboxString(normalized)}")`);
		}
	}
	return filters;
}

function hasExactSamePolicyAllow(effective: EffectivePolicy, deny: Rule, allowKind: RuleKind): boolean {
	const denyAbs = normalize(absolutePattern(deny));
	return effective.rules.some(
		(rule) => rule.kind === allowKind && rule.policy.id === deny.policy.id && normalize(absolutePattern(rule)) === denyAbs,
	);
}

function buildMacSandboxProfile(effective: EffectivePolicy): string {
	const lines = ["(version 1)", "(allow default)"];
	const denyRead = effective.rules.filter(
		(r) => r.kind === "denyRead" && !hasExactSamePolicyAllow(effective, r, "allowRead"),
	);
	const denyWrite = effective.rules.filter(
		(r) => r.kind === "denyWrite" && !hasExactSamePolicyAllow(effective, r, "allowWrite"),
	);

	for (const rule of denyRead) {
		const filters = sandboxFiltersForRule(rule);
		if (filters.length > 0) lines.push(`(deny file-read* ${filters.join(" ")})`);
	}
	for (const rule of denyWrite) {
		const filters = sandboxFiltersForRule(rule);
		if (filters.length > 0) lines.push(`(deny file-write* ${filters.join(" ")})`);
	}
	return `${lines.join("\n")}\n`;
}

function createMacSandboxedBashOps(): BashOperations {
	return {
		async exec(command, cwd, { onData, signal, timeout }) {
			const effective = loadEffectivePolicy(cwd);
			const profile = buildMacSandboxProfile(effective);
			const profilePath = path.join(os.tmpdir(), `pi-file-guard-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}.sb`);
			writeFileSync(profilePath, profile);

			return new Promise((resolve, reject) => {
				const child = spawn("/usr/bin/sandbox-exec", ["-f", profilePath, "/bin/bash", "-lc", command], {
					cwd,
					detached: true,
					stdio: ["ignore", "pipe", "pipe"],
				});

				let timedOut = false;
				let timeoutHandle: NodeJS.Timeout | undefined;
				const cleanup = () => {
					try {
						unlinkSync(profilePath);
					} catch {}
				};

				if (timeout !== undefined && timeout > 0) {
					timeoutHandle = setTimeout(() => {
						timedOut = true;
						if (child.pid) {
							try {
								process.kill(-child.pid, "SIGKILL");
							} catch {
								child.kill("SIGKILL");
							}
						}
					}, timeout * 1000);
				}

				child.stdout?.on("data", onData);
				child.stderr?.on("data", onData);

				const onAbort = () => {
					if (child.pid) {
						try {
							process.kill(-child.pid, "SIGKILL");
						} catch {
							child.kill("SIGKILL");
						}
					}
				};

				signal?.addEventListener("abort", onAbort, { once: true });

				child.on("error", (err) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					signal?.removeEventListener("abort", onAbort);
					cleanup();
					reject(err);
				});

				child.on("close", (code) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					signal?.removeEventListener("abort", onAbort);
					cleanup();

					if (signal?.aborted) reject(new Error("aborted"));
					else if (timedOut) reject(new Error(`timeout:${timeout}`));
					else resolve({ exitCode: code });
				});
			});
		},
	};
}

function collectLinuxDeniedOverlays(effective: EffectivePolicy, cwd: string): Array<{ source: string; target: string }> {
	const overlays: Array<{ source: string; target: string }> = [];
	const emptyFile = path.join(os.tmpdir(), `pi-file-guard-empty-file-${process.pid}`);
	const emptyDir = path.join(os.tmpdir(), `pi-file-guard-empty-dir-${process.pid}`);
	if (!existsSync(emptyFile)) closeSync(openSync(emptyFile, "w"));
	mkdirSync(emptyDir, { recursive: true });

	const add = (target: string) => {
		try {
			const st = statSync(target);
			overlays.push({ source: st.isDirectory() ? emptyDir : emptyFile, target });
		} catch {}
	};

	const scanForBasename = (root: string, basename: string) => {
		let visited = 0;
		const walk = (dir: string) => {
			if (++visited > 10000) return;
			let entries: string[];
			try {
				entries = readdirSync(dir);
			} catch {
				return;
			}
			for (const entry of entries) {
				const full = path.join(dir, entry);
				if (entry === basename) add(full);
				if (entry === ".git" || entry === "node_modules" || entry === ".next" || entry === "dist" || entry === "build") continue;
				try {
					if (statSync(full).isDirectory()) walk(full);
				} catch {}
			}
		};
		walk(root);
	};

	for (const rule of effective.rules) {
		if (rule.kind !== "denyRead") continue;
		const abs = absolutePattern(rule);
		if (!hasGlob(abs)) {
			add(abs);
			continue;
		}
		const base = path.basename(abs);
		if (base && !hasGlob(base)) scanForBasename(cwd, base);
	}
	return overlays;
}

function createLinuxSandboxedBashOps(): BashOperations {
	return {
		async exec(command, cwd, { onData, signal, timeout }) {
			const bwrap = linuxSandboxExecutable();
			if (!bwrap) throw new Error("bubblewrap not found");
			const effective = loadEffectivePolicy(cwd);
			const args = [
				"--die-with-parent",
				"--new-session",
				"--proc", "/proc",
				"--dev", "/dev",
				"--tmpfs", "/tmp",
			];
			const bindIfExists = (flag: "--bind" | "--ro-bind", source: string, target = source) => {
				if (existsSync(source)) args.push(flag, source, target);
			};
			bindIfExists("--ro-bind", "/nix");
			bindIfExists("--ro-bind", "/etc");
			bindIfExists("--ro-bind", "/run/current-system");
			bindIfExists("--bind", HOME);
			args.push(
				"--chdir", cwd,
				"--setenv", "HOME", HOME,
				"--setenv", "PATH", process.env.PATH ?? "",
			);
			for (const overlay of collectLinuxDeniedOverlays(effective, cwd)) {
				args.push("--ro-bind", overlay.source, overlay.target);
			}
			args.push("/bin/bash", "-lc", command);

			return new Promise((resolve, reject) => {
				const child = spawn(bwrap, args, { cwd, detached: true, stdio: ["ignore", "pipe", "pipe"] });
				let timedOut = false;
				let timeoutHandle: NodeJS.Timeout | undefined;
				if (timeout !== undefined && timeout > 0) {
					timeoutHandle = setTimeout(() => {
						timedOut = true;
						if (child.pid) {
							try { process.kill(-child.pid, "SIGKILL"); } catch { child.kill("SIGKILL"); }
						}
					}, timeout * 1000);
				}
				child.stdout?.on("data", onData);
				child.stderr?.on("data", onData);
				const onAbort = () => {
					if (child.pid) {
						try { process.kill(-child.pid, "SIGKILL"); } catch { child.kill("SIGKILL"); }
					}
				};
				signal?.addEventListener("abort", onAbort, { once: true });
				child.on("error", (err) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					signal?.removeEventListener("abort", onAbort);
					reject(err);
				});
				child.on("close", (code) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					signal?.removeEventListener("abort", onAbort);
					if (signal?.aborted) reject(new Error("aborted"));
					else if (timedOut) reject(new Error(`timeout:${timeout}`));
					else resolve({ exitCode: code });
				});
			});
		},
	};
}

function hasSandboxRelevantRules(effective: EffectivePolicy): boolean {
	return effective.rules.some((r) => r.kind === "denyRead" || r.kind === "denyWrite");
}

async function shouldAllowUnsandboxedBash(effective: EffectivePolicy, command: string, ctx: any): Promise<boolean> {
	if (effective.mode === "off" || effective.mode === "warn" || !hasSandboxRelevantRules(effective)) return true;
	if (canUseMacSandbox() || canUseLinuxSandbox()) return true;
	if (effective.mode === "prompt" && ctx.hasUI) {
		const choice = await ctx.ui.select(
			`File guard cannot sandbox bash on this platform. Allow unsandboxed command?\n\n${command}`,
			["Block", "Allow once"],
		);
		return choice === "Allow once";
	}
	return false;
}

export default function fileGuard(pi: ExtensionAPI) {
	const plainBash = createBashTool(process.cwd());

	pi.on("session_start", async (_event, ctx) => {
		const effective = loadEffectivePolicy(ctx.cwd);
		ctx.ui.setStatus("file-guard", ctx.ui.theme.fg("accent", modeSummary(effective)));
	});

	pi.on("tool_call", async (event, ctx) => {
		const effective = loadEffectivePolicy(ctx.cwd);
		if (effective.mode === "off") return undefined;

		if (isToolCallEventType("read", event)) {
			const decision = shouldBlock(effective, "read", candidatePaths(ctx.cwd, event.input.path));
			if (decision.block) return handleBlockedTool(ctx, effective, "read", event.input.path, decision.rule);
		}

		if (event.toolName === "write" || event.toolName === "edit") {
			const input = event.input as { path?: unknown };
			if (typeof input.path !== "string") return undefined;
			const decision = shouldBlock(effective, "write", candidatePaths(ctx.cwd, input.path));
			if (decision.block) return handleBlockedTool(ctx, effective, "write", input.path, decision.rule);
		}

		return undefined;
	});

	pi.registerTool({
		...plainBash,
		label: "bash (file guarded)",
		async execute(id, params, signal, onUpdate, ctx) {
			const effective = loadEffectivePolicy(ctx.cwd);
			if (!(await shouldAllowUnsandboxedBash(effective, params.command, ctx))) {
				return {
					content: [
						{
							type: "text",
							text: "File guard blocked bash because denied file rules exist and no OS sandbox is available.",
						},
					],
					details: { blocked: true },
				};
			}

			if (hasSandboxRelevantRules(effective) && effective.mode !== "off" && effective.mode !== "warn") {
				if (canUseMacSandbox()) {
					const sandboxed = createBashTool(process.cwd(), { operations: createMacSandboxedBashOps() });
					return sandboxed.execute(id, params, signal, onUpdate);
				}
				if (canUseLinuxSandbox()) {
					const sandboxed = createBashTool(process.cwd(), { operations: createLinuxSandboxedBashOps() });
					return sandboxed.execute(id, params, signal, onUpdate);
				}
			}

			return plainBash.execute(id, params, signal, onUpdate);
		},
	});

	pi.on("user_bash", async (event, ctx) => {
		const effective = loadEffectivePolicy(event.cwd ?? ctx.cwd);
		if (!(await shouldAllowUnsandboxedBash(effective, event.command, ctx))) {
			return {
				result: {
					output: "File guard blocked bash because denied file rules exist and no OS sandbox is available.",
					exitCode: 1,
					cancelled: false,
					truncated: false,
				},
			};
		}
		if (hasSandboxRelevantRules(effective) && effective.mode !== "off" && effective.mode !== "warn") {
			if (canUseMacSandbox()) return { operations: createMacSandboxedBashOps() };
			if (canUseLinuxSandbox()) return { operations: createLinuxSandboxedBashOps() };
		}
		return undefined;
	});

	pi.registerCommand("guard", {
		description: "Manage file guard deny/allow rules",
		handler: async (args, ctx) => {
			const [cmd, ...rest] = args.trim().split(/\s+/).filter(Boolean);
			const effective = loadEffectivePolicy(ctx.cwd);

			if (!cmd || cmd === "status") {
				const lines = [
					modeSummary(effective),
					"",
					"Active policy files:",
					...(effective.policies.length
						? effective.policies.map((p) => `  ${policyScope(p)}: ${displayPath(p.path)}`)
						: ["  (none)"]),
					"",
					"Commands: /guard deny <path|glob>, /guard allow <path|glob>, /guard remove [kind] <path|glob>, /guard list, /guard mode <strict|prompt|warn|off>, /guard edit [user|project|path]",
				];
				ctx.ui.notify(lines.join("\n"), "info");
				return;
			}

			if (cmd === "list") {
				const lines = effective.rules.length
					? effective.rules.map((r) => `${r.kind.padEnd(10)} ${formatRule(r)}`)
					: ["No file guard rules configured."];
				ctx.ui.notify(lines.join("\n"), "info");
				return;
			}

			if (cmd === "mode") {
				const mode = rest[0];
				if (!isMode(mode)) {
					ctx.ui.notify("Usage: /guard mode strict|prompt|warn|off", "error");
					return;
				}
				const config = readJsonConfig(GLOBAL_POLICY_PATH);
				config.mode = mode;
				writeJsonConfig(GLOBAL_POLICY_PATH, config);
				ctx.ui.setStatus("file-guard", ctx.ui.theme.fg("accent", modeSummary(loadEffectivePolicy(ctx.cwd))));
				ctx.ui.notify(`File guard mode set to ${mode} in ${GLOBAL_POLICY_PATH}`, "info");
				return;
			}

			if (cmd === "deny" || cmd === "allow") {
				const rawPattern = rest.join(" ");
				if (!rawPattern) {
					ctx.ui.notify(`Usage: /guard ${cmd} <path-or-glob>`, "error");
					return;
				}
				const target = policyTargetForRule(ctx.cwd, rawPattern);
				const kind: RuleKind = cmd === "deny" ? "denyRead" : "allowRead";
				addRule(target.file, kind, target.stored);
				ctx.ui.setStatus("file-guard", ctx.ui.theme.fg("accent", modeSummary(loadEffectivePolicy(ctx.cwd))));
				ctx.ui.notify(`Added ${kind} rule ${target.stored} to ${target.file}`, "info");
				return;
			}

			if (cmd === "remove" || cmd === "rm") {
				if (rest.length === 0) {
					if (!ctx.hasUI || effective.rules.length === 0) {
						ctx.ui.notify("Usage: /guard remove [deny|allow|read|write|denyRead|allowRead|denyWrite|allowWrite] <path-or-glob>", "error");
						return;
					}
					const items = effective.rules.map((r, i) => `${i + 1}. ${r.kind} ${formatRule(r)}`);
					const selected = await ctx.ui.select("Remove file guard rule", items);
					const index = selected ? items.indexOf(selected) : -1;
					const rule = index >= 0 ? effective.rules[index] : undefined;
					if (!rule) return;
					const removed = removeRule(rule.policy.path, [rule.kind], new Set([rule.pattern]));
					ctx.ui.setStatus("file-guard", ctx.ui.theme.fg("accent", modeSummary(loadEffectivePolicy(ctx.cwd))));
					ctx.ui.notify(removed ? `Removed ${rule.kind} ${rule.pattern} from ${rule.policy.path}` : "Rule not found", removed ? "info" : "warning");
					return;
				}

				const parsed = parseRuleKinds(rest[0]);
				const rawPattern = rest.slice(parsed.consumed ? 1 : 0).join(" ");
				if (!rawPattern) {
					ctx.ui.notify("Usage: /guard remove [kind] <path-or-glob>", "error");
					return;
				}

				let removed = 0;
				for (const policy of effective.policies) {
					removed += removeRule(policy.path, parsed.kinds, removalCandidates(rawPattern, ctx.cwd, policy));
				}
				ctx.ui.setStatus("file-guard", ctx.ui.theme.fg("accent", modeSummary(loadEffectivePolicy(ctx.cwd))));
				ctx.ui.notify(
					removed ? `Removed ${removed} rule(s) matching ${rawPattern}` : `No active rule matched ${rawPattern}`,
					removed ? "info" : "warning",
				);
				return;
			}

			if (cmd === "edit") {
				const projectTarget = policyTargetForRule(ctx.cwd, ".");
				const targetMap = new Map<string, string>();
				const seenFiles = new Set<string>();
				const addTarget = (label: string, file: string) => {
					const resolved = path.resolve(file);
					if (seenFiles.has(resolved)) return;
					seenFiles.add(resolved);
					targetMap.set(label, resolved);
				};

				addTarget(`user policy (${displayPath(GLOBAL_POLICY_PATH)})`, GLOBAL_POLICY_PATH);
				addTarget(`current workspace policy (${displayPath(projectTarget.file)})`, projectTarget.file);
				for (const policy of effective.policies) {
					addTarget(`active ${policyScope(policy)} policy (${displayPath(policy.path)})`, policy.path);
				}

				let file = GLOBAL_POLICY_PATH;
				if (rest[0] === "user" || rest[0] === "global") file = GLOBAL_POLICY_PATH;
				else if (rest[0] === "project" || rest[0] === "workspace") file = projectTarget.file;
				else if (rest.length > 0) file = path.resolve(ctx.cwd, rest.join(" "));
				else if (ctx.hasUI) {
					const labels = [...targetMap.keys()];
					const selected = await ctx.ui.select("Edit which file guard policy?", labels);
					if (!selected) return;
					file = targetMap.get(selected) ?? GLOBAL_POLICY_PATH;
				}

				const current = existsSync(file)
					? readFileSync(file, "utf-8")
					: `${JSON.stringify({ denyRead: [], allowRead: [], denyWrite: [], allowWrite: [] }, null, "\t")}\n`;
				const edited = await ctx.ui.editor(`Edit file guard policy: ${file}`, current);
				if (edited === null || edited === undefined) return;
				try {
					JSON.parse(edited);
					mkdirSync(path.dirname(file), { recursive: true });
					writeFileSync(file, edited.endsWith("\n") ? edited : `${edited}\n`);
					ctx.ui.setStatus("file-guard", ctx.ui.theme.fg("accent", modeSummary(loadEffectivePolicy(ctx.cwd))));
					ctx.ui.notify(`Saved ${file}`, "info");
				} catch (err) {
					ctx.ui.notify(`Invalid JSON: ${err instanceof Error ? err.message : String(err)}`, "error");
				}
				return;
			}

			ctx.ui.notify("Usage: /guard [status|list|deny|allow|remove|mode|edit]", "error");
		},
	});
}
