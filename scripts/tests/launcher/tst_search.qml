import QtQuick
import QtTest
import "../../../dotfiles/quickshell/bar/LauncherSearch.js" as Search

TestCase {
    name: "LauncherSearch"

    function entry(id, name, extra) {
        return Object.assign({id: id, name: name, genericName: "", comment: "", keywords: [], command: [id], noDisplay: false, runInTerminal: false, workingDirectory: ""}, extra || {});
    }

    function test_emptyQueryAndHidden() {
        const apps = [entry("z", "Zen"), entry("a", "Alpha"), entry("hidden", "Hidden", {noDisplay: true}), entry("empty", "Empty", {command: []})];
        compare(Search.rank(apps, "  ").map(app => app.id), ["a", "z"]);
    }

    function test_ranking() {
        const apps = [entry("contains", "My Kitty"), entry("prefix", "Kitty tools"), entry("exact", "Kitty"), entry("fuzzy", "Kite typography")];
        compare(Search.rank(apps, "kitty").map(app => app.id), ["exact", "prefix", "contains", "fuzzy"]);
    }

    function test_keywordsAndMultipleWords() {
        const apps = [entry("zen", "Zen", {genericName: "Web Browser", keywords: ["Internet"]}), entry("kitty", "Kitty", {genericName: "Terminal"})];
        compare(Search.rank(apps, "internet web")[0].id, "zen");
        compare(Search.rank(apps, "WEB browser")[0].id, "zen");
        compare(Search.rank(apps, "kit" )[0].id, "kitty");
        compare(Search.rank(apps, "zzzzzz").length, 0);
    }

    function test_unicodeAndExecutable() {
        const apps = [entry("editor", "Éditeur", {command: ["/nix/store/example/bin/my-editor"]})];
        compare(Search.rank(apps, "editeur").length, 1);
        compare(Search.rank(apps, "my-editor").length, 1);
        compare(Search.rank(apps, "nix/store").length, 0);
    }

    function test_literalInput() {
        const apps = [entry("kitty", "Kitty")];
        compare(Search.rank(apps, "$(touch /tmp/should-not-exist)").length, 0);
    }

    function test_launchArguments() {
        const app = entry("editor", "Editor", {command: ["editor", "a file with spaces", "$(not-a-shell-command)"], workingDirectory: "/tmp/project with spaces"});
        compare(Search.launchOptions(app), {command: app.command, workingDirectory: app.workingDirectory});
        app.runInTerminal = true;
        compare(Search.launchOptions(app), {command: ["kitty", "--", "editor", "a file with spaces", "$(not-a-shell-command)"], workingDirectory: app.workingDirectory});
        compare(app.command[0], "editor");
    }
}
