#!/usr/bin/env node

const BASH_PATTERNS = [
  /gh pr create/,
  /gh pr comment/,
  /gh pr edit/,
  /gh issue create/,
  /gh issue comment/,
  /git commit/,
];

// Files whose content goes public (committed code, changelogs, etc.)
const PUBLIC_FILE_PATTERNS = [
  /CHANGELOG/i,
  /\.md$/,
  /commit[-_]?msg/i,
];

const REMINDER = [
  "HUMANIZER: this text goes to other people. before finalizing:",
  "- no AI vocab (ensure, leverage, utilize, showcase, pivotal, crucial, robust, seamless, foster)",
  '- no "proper" as filler',
  "- active voice; terse; no fluff; errors explain the fix",
  "- match pedro's style: direct, lowercase-friendly, fragments over full sentences",
].join("\n");

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  try {
    const data = JSON.parse(input);
    const tool = data?.tool_name || "";
    const ti = data?.tool_input || {};

    if (tool === "Bash") {
      const command = ti.command || "";
      if (BASH_PATTERNS.some((p) => p.test(command))) {
        console.log(REMINDER);
      }
      return;
    }

    if (tool === "Edit" || tool === "Write") {
      const filePath = ti.file_path || "";
      if (PUBLIC_FILE_PATTERNS.some((p) => p.test(filePath))) {
        console.log(REMINDER);
      }
    }
  } catch (_) {
    // ignore parse errors
  }
});
