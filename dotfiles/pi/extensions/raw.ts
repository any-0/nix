import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { inspect } from "node:util";

type ContentBlock = {
  type?: string;
  text?: string;
  thinking?: string;
  name?: string;
  id?: string;
  arguments?: unknown;
  mimeType?: string;
  data?: string;
  redacted?: boolean;
};

type ModelMessage = {
  role?: string;
  content?: string | ContentBlock[];
  toolCallId?: string;
  toolName?: string;
  isError?: boolean;
  command?: string;
  output?: string;
  exitCode?: number;
  cancelled?: boolean;
  truncated?: boolean;
  fullOutputPath?: string;
  excludeFromContext?: boolean;
  summary?: string;
};

type SessionEntry = {
  type: string;
  id: string;
  message?: ModelMessage;
  customType?: string;
  content?: string | ContentBlock[];
  summary?: string;
  firstKeptEntryId?: string;
  tokensBefore?: number;
};

const COMPACTION_SUMMARY_PREFIX = "The conversation history before this point was compacted into the following summary:\n\n<summary>\n";
const COMPACTION_SUMMARY_SUFFIX = "\n</summary>";
const BRANCH_SUMMARY_PREFIX = "The following is a summary of a branch that this conversation came back from:\n\n<summary>\n";
const BRANCH_SUMMARY_SUFFIX = "</summary>";

function asJson(value: unknown): string {
  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return inspect(value, { depth: null, colors: false });
  }
}

function textMessage(text: string): ModelMessage {
  return {
    role: "user",
    content: [{ type: "text", text }],
  };
}

function bashExecutionToText(message: ModelMessage): string {
  let text = `Ran \`${message.command ?? ""}\`\n`;

  if (message.output) {
    text += `\`\`\`\n${message.output}\n\`\`\``;
  } else {
    text += "(no output)";
  }

  if (message.cancelled) {
    text += "\n\n(command cancelled)";
  } else if (message.exitCode !== null && message.exitCode !== undefined && message.exitCode !== 0) {
    text += `\n\nCommand exited with code ${message.exitCode}`;
  }

  if (message.truncated && message.fullOutputPath) {
    text += `\n\n[Output truncated. Full output: ${message.fullOutputPath}]`;
  }

  return text;
}

function messageToModelContext(message: ModelMessage): ModelMessage | undefined {
  if (message.role === "bashExecution") {
    if (message.excludeFromContext) return undefined;
    return textMessage(bashExecutionToText(message));
  }

  if (message.role === "custom") {
    return {
      role: "user",
      content: message.content,
    };
  }

  if (message.role === "branchSummary") {
    return textMessage(BRANCH_SUMMARY_PREFIX + (message.summary ?? "") + BRANCH_SUMMARY_SUFFIX);
  }

  if (message.role === "compactionSummary") {
    return textMessage(COMPACTION_SUMMARY_PREFIX + (message.summary ?? "") + COMPACTION_SUMMARY_SUFFIX);
  }

  return message;
}

function messageFromEntry(entry: SessionEntry): ModelMessage | undefined {
  if (entry.type === "message") {
    return entry.message ? messageToModelContext(entry.message) : undefined;
  }

  if (entry.type === "custom_message") {
    return {
      role: "user",
      content: entry.content,
    };
  }

  if (entry.type === "branch_summary" && entry.summary) {
    return textMessage(BRANCH_SUMMARY_PREFIX + entry.summary + BRANCH_SUMMARY_SUFFIX);
  }

  return undefined;
}

function messagesFromBranch(branch: SessionEntry[]): ModelMessage[] {
  const compactionIndex = branch.findLastIndex((entry) => entry.type === "compaction");

  if (compactionIndex === -1) {
    return branch.map(messageFromEntry).filter((message): message is ModelMessage => message !== undefined);
  }

  const compaction = branch[compactionIndex];
  const messages = [
    textMessage(COMPACTION_SUMMARY_PREFIX + (compaction.summary ?? "") + COMPACTION_SUMMARY_SUFFIX),
  ];

  let foundFirstKept = false;
  for (let index = 0; index < compactionIndex; index++) {
    const entry = branch[index];
    if (entry.id === compaction.firstKeptEntryId) {
      foundFirstKept = true;
    }

    if (foundFirstKept) {
      const message = messageFromEntry(entry);
      if (message) messages.push(message);
    }
  }

  for (let index = compactionIndex + 1; index < branch.length; index++) {
    const message = messageFromEntry(branch[index]);
    if (message) messages.push(message);
  }

  return messages;
}

function formatContent(content: ModelMessage["content"]): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content.map((block) => {
    if (block.type === "text") return block.text ?? "";

    if (block.type === "thinking") {
      const body = block.redacted ? "[redacted]" : (block.thinking ?? "");
      return `<thinking>\n${body}\n</thinking>`;
    }

    if (block.type === "toolCall") {
      return [
        `<tool_call name="${block.name ?? ""}" id="${block.id ?? ""}">`,
        asJson(block.arguments ?? {}),
        "</tool_call>",
      ].join("\n");
    }

    if (block.type === "image") {
      const bytes = block.data ? Buffer.byteLength(block.data, "base64") : 0;
      return `[image mimeType="${block.mimeType ?? "unknown"}" bytes=${bytes}]`;
    }

    return asJson(block);
  }).filter(Boolean).join("\n\n");
}

function formatMessage(message: ModelMessage): string {
  const role = (message.role ?? "message").toUpperCase();

  if (message.role === "toolResult") {
    const status = message.isError ? " error=true" : "";
    return [
      `## TOOL RESULT ${message.toolName ?? ""} id=${message.toolCallId ?? ""}${status}`,
      formatContent(message.content),
    ].join("\n\n");
  }

  return [
    `## ${role}`,
    formatContent(message.content),
  ].join("\n\n");
}

function formatTranscript(systemPrompt: string, messages: ModelMessage[]): string {
  return [
    "## SYSTEM",
    systemPrompt,
    ...messages.map(formatMessage),
  ].join("\n\n---\n\n").trim();
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("raw", {
    description: "Show the model-facing transcript for the active branch",
    handler: async (_args, ctx) => {
      await ctx.waitForIdle();
      if (!ctx.hasUI) return;

      const messages = messagesFromBranch(ctx.sessionManager.getBranch() as SessionEntry[]);
      if (messages.length === 0) {
        ctx.ui.notify("No model-facing context found in this session.", "warning");
        return;
      }

      const transcript = formatTranscript(ctx.getSystemPrompt(), messages);
      await ctx.ui.editor("Raw model transcript", transcript);
    },
  });
}
