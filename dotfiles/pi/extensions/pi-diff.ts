import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type ContentBlock = {
	type?: string;
	id?: string;
	name?: string;
	arguments?: any;
};

type SessionEntry = {
	timestamp?: string;
	message?: {
		role?: string;
		content?: ContentBlock[] | string;
		toolCallId?: string;
		toolName?: string;
		details?: { diff?: string; firstChangedLine?: number };
	};
};

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function findToolCallArgs(branch: SessionEntry[], toolCallId: string): any | undefined {
	for (const entry of branch) {
		const content = entry.message?.content;
		if (!Array.isArray(content)) continue;

		for (const block of content) {
			if (block.type === "toolCall" && block.id === toolCallId) {
				return block.arguments;
			}
		}
	}
}

function openFile(path: string, line: number, ctx: any): Promise<number | null> {
	const editor = process.env.EDITOR || "vi";
	const command = `${editor} +${line} ${shellQuote(path)}`;
	const shell = process.env.SHELL || "/bin/sh";

	return ctx.ui.custom<number | null>((tui: any, _theme: any, _kb: any, done: (value: number | null) => void) => {
		tui.stop();
		process.stdout.write("\x1b[2J\x1b[H");
		const result = spawnSync(shell, ["-lc", command], {
			stdio: "inherit",
			env: process.env,
			cwd: ctx.cwd,
		});
		tui.start();
		tui.requestRender(true);
		done(result.status);
		return { render: () => [], invalidate: () => {} };
	});
}

export default function piDiffExtension(pi: ExtensionAPI) {
	pi.registerCommand("diff", {
		description: "Open the file from the latest pi diff in $EDITOR at the changed line",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return;

			const branch = ctx.sessionManager.getBranch() as SessionEntry[];
			const diffEntry = branch
				.slice()
				.reverse()
				.find((entry) => entry.message?.role === "toolResult" && entry.message.details?.diff);

			if (!diffEntry?.message) {
				ctx.ui.notify("No pi diffs found in this session branch", "warning");
				return;
			}

			const toolCallId = diffEntry.message.toolCallId;
			const args = toolCallId ? findToolCallArgs(branch, toolCallId) : undefined;
			const file = args?.path;

			if (!file || typeof file !== "string") {
				ctx.ui.notify("Could not determine the file for the latest diff", "warning");
				return;
			}

			const line = diffEntry.message.details?.firstChangedLine ?? 1;
			const path = resolve(ctx.cwd, file);
			const exitCode = await openFile(path, line, ctx);

			if (exitCode !== 0) {
				ctx.ui.notify(`$EDITOR exited with code ${exitCode ?? "unknown"}`, "warning");
			}
		},
	});
}
