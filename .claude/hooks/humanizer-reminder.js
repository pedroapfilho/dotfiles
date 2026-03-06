#!/usr/bin/env node

const PUBLISH_PATTERNS = [
  /gh pr create/,
  /gh pr comment/,
  /gh pr edit/,
  /gh issue create/,
  /gh issue comment/,
  /git commit/,
];

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  try {
    const data = JSON.parse(input);
    const command = data?.tool_input?.command || "";

    if (PUBLISH_PATTERNS.some((p) => p.test(command))) {
      console.log(
        [
          "HUMANIZER: this text goes to other people. before finalizing:",
          "- no AI vocab (ensure, leverage, utilize, showcase, pivotal, crucial, robust, seamless, foster)",
          '- no "proper" as filler',
          "- active voice; terse; no fluff; errors explain the fix",
          "- match pedro's style: direct, lowercase-friendly, fragments over full sentences",
        ].join("\n")
      );
    }
  } catch (_) {
    // ignore parse errors
  }
});
