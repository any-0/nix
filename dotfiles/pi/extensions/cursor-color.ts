import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CURSOR_BG: [number, number, number] = [0x00, 0x93, 0x93];
const CURSOR_FG: [number, number, number] = [0x00, 0x00, 0x00];

const CURSOR_STYLE = `\x1b[38;2;${CURSOR_FG[0]};${CURSOR_FG[1]};${CURSOR_FG[2]}m\x1b[48;2;${CURSOR_BG[0]};${CURSOR_BG[1]};${CURSOR_BG[2]}m`;

function recolorCursor(line: string): string {
	return line.replace(/\x1b\[7m([\s\S]*?)\x1b\[(?:0|27)m/g, (_match, char: string) => `${CURSOR_STYLE}${char}\x1b[0m`);
}

class CursorColorEditor extends CustomEditor {
	render(width: number): string[] {
		return super.render(width).map(recolorCursor);
	}
}

export default function cursorColorExtension(pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;

		ctx.ui.setEditorComponent((tui, theme, keybindings) => new CursorColorEditor(tui, theme, keybindings));
	});
}
