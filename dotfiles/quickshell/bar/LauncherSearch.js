.pragma library

function normalize(text) {
    return text.normalize("NFKD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function matchScore(text, query) {
    if (text === query) return 0;
    if (text.startsWith(query)) return 10;
    const position = text.indexOf(query);
    if (position >= 0) return 20 + position;

    let cursor = 0;
    let gaps = 0;
    for (const character of query) {
        const next = text.indexOf(character, cursor);
        if (next < 0) return Infinity;
        gaps += next - cursor;
        cursor = next + 1;
    }
    return 100 + gaps;
}

function rank(entries, query) {
    const tokens = normalize(query.trim()).split(/\s+/).filter(token => token.length > 0);
    return entries.filter(entry => !entry.noDisplay && entry.command.length > 0).map(entry => {
        const name = normalize(entry.name);
        const metadata = normalize([entry.genericName, entry.comment, entry.keywords.join(" "), entry.id, entry.command[0].split("/").pop()].join(" "));
        const score = tokens.reduce((total, token) => total + Math.min(matchScore(name, token), metadata.includes(token) ? 60 : Infinity), 0);
        return {entry: entry, score: score};
    }).filter(result => Number.isFinite(result.score)).sort((a, b) => a.score - b.score || a.entry.name.localeCompare(b.entry.name)).map(result => result.entry);
}

function launchOptions(entry) {
    return {
        command: entry.runInTerminal ? ["kitty", "--"].concat(Array.from(entry.command)) : Array.from(entry.command),
        workingDirectory: entry.workingDirectory
    };
}
