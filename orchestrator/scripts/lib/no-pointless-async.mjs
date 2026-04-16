#!/usr/bin/env node
// AST scan: find Server Component files (page/layout/template/default) whose
// default-exported function is `async` but contains no `await` in its own body.
// Nested function awaits don't count — they belong to a different scope.

import {
  walkApps,
  parseTsx,
  isAsync,
  findDefaultExportFunction,
  runVerifier,
} from "./ast-helpers.mjs";

const TARGET_FILES = new Set(["page.tsx", "layout.tsx", "template.tsx", "default.tsx"]);

const hasOwnAwait = (ts, fnNode) => {
  let found = false;
  const visit = (node) => {
    if (found || !node) return;
    if (node.kind === ts.SyntaxKind.AwaitExpression) {
      found = true;
      return;
    }
    if (node.kind === ts.SyntaxKind.ForOfStatement && node.awaitModifier) {
      found = true;
      return;
    }
    const isNestedFn =
      node.kind === ts.SyntaxKind.FunctionDeclaration ||
      node.kind === ts.SyntaxKind.FunctionExpression ||
      node.kind === ts.SyntaxKind.ArrowFunction ||
      node.kind === ts.SyntaxKind.MethodDeclaration;
    if (isNestedFn && node !== fnNode) return;
    ts.forEachChild(node, visit);
  };
  ts.forEachChild(fnNode, visit);
  return found;
};

runVerifier((ts, repoPath) => {
  const offenders = [];
  for (const file of walkApps(repoPath, TARGET_FILES)) {
    const sf = parseTsx(ts, file);
    const fn = findDefaultExportFunction(ts, sf);
    if (!fn || !isAsync(ts, fn) || hasOwnAwait(ts, fn)) continue;
    const { line } = sf.getLineAndCharacterOfPosition(fn.getStart(sf));
    offenders.push(`${file.replace(repoPath + "/", "")}:${line + 1}`);
  }
  return offenders;
});
