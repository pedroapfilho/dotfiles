// Shared helpers for AST-level verifiers.
// Each verifier passes its target repoPath; we load that repo's bundled
// TypeScript via createRequire — keeps the orchestrator dependency-free.

import { createRequire } from "node:module";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const DEFAULT_SKIP_DIRS = new Set([
  "node_modules",
  ".next",
  ".turbo",
  "dist",
  "generated",
  ".git",
]);

export const loadTypescript = (repoPath) => {
  const require = createRequire(join(repoPath, "package.json"));
  return require("typescript");
};

// Yield every file under `root` whose basename satisfies `match` (Set or fn).
// Skips DEFAULT_SKIP_DIRS plus any extras.
export function* walkFiles(root, match, extraSkipDirs = []) {
  const skip = new Set([...DEFAULT_SKIP_DIRS, ...extraSkipDirs]);
  const test =
    match instanceof Set ? (name) => match.has(name) : match;

  let entries;
  try {
    entries = readdirSync(root, { withFileTypes: true });
  } catch {
    return;
  }

  for (const entry of entries) {
    const full = join(root, entry.name);
    if (entry.isDirectory()) {
      if (skip.has(entry.name)) continue;
      yield* walkFiles(full, match, extraSkipDirs);
    } else if (test(entry.name)) {
      yield full;
    }
  }
}

// Walk `apps/` for files whose basename matches. Returns [] if no apps/ dir.
export function* walkApps(repoPath, match, extraSkipDirs = []) {
  const appsDir = join(repoPath, "apps");
  try {
    statSync(appsDir);
  } catch {
    return;
  }
  yield* walkFiles(appsDir, match, extraSkipDirs);
}

export const parseTsx = (ts, file) => {
  const src = readFileSync(file, "utf8");
  return ts.createSourceFile(file, src, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
};

export const hasModifier = (ts, node, kind) =>
  node.modifiers?.some((m) => m.kind === kind) ?? false;

export const isAsync = (ts, node) =>
  hasModifier(ts, node, ts.SyntaxKind.AsyncKeyword);

// Find the function node a file's `export default` ultimately points to.
// Handles three patterns:
//   1. export default function Foo() {}
//   2. export default () => {} / function() {}
//   3. const Foo = () => {}; export default Foo;
// Returns the FunctionDeclaration / ArrowFunction / FunctionExpression, or null.
export const findDefaultExportFunction = (ts, sourceFile) => {
  let inlineDefault = null;
  const localFns = new Map();

  ts.forEachChild(sourceFile, (node) => {
    if (
      node.kind === ts.SyntaxKind.FunctionDeclaration &&
      hasModifier(ts, node, ts.SyntaxKind.ExportKeyword) &&
      hasModifier(ts, node, ts.SyntaxKind.DefaultKeyword)
    ) {
      inlineDefault = node;
      return;
    }
    if (node.kind === ts.SyntaxKind.FunctionDeclaration && node.name) {
      localFns.set(node.name.text, node);
    }
    if (node.kind === ts.SyntaxKind.VariableStatement) {
      for (const decl of node.declarationList.declarations) {
        if (
          decl.name?.kind === ts.SyntaxKind.Identifier &&
          decl.initializer &&
          (decl.initializer.kind === ts.SyntaxKind.ArrowFunction ||
            decl.initializer.kind === ts.SyntaxKind.FunctionExpression)
        ) {
          localFns.set(decl.name.text, decl.initializer);
        }
      }
    }
  });

  if (inlineDefault) return inlineDefault;

  let resolved = null;
  ts.forEachChild(sourceFile, (node) => {
    if (resolved || node.kind !== ts.SyntaxKind.ExportAssignment) return;
    const expr = node.expression;
    if (!expr) return;
    if (
      expr.kind === ts.SyntaxKind.ArrowFunction ||
      expr.kind === ts.SyntaxKind.FunctionExpression
    ) {
      resolved = expr;
    } else if (expr.kind === ts.SyntaxKind.Identifier) {
      const local = localFns.get(expr.text);
      if (local) resolved = local;
    }
  });
  return resolved;
};

// Standard CLI shape for an AST verifier:
//   node my-rule.mjs <repoPath>
// Exits 0 if clean, 1 if `runRule(ts, repoPath)` returns a non-empty array of
// "path:line" strings, 2 on usage / load errors. Errors go to stderr.
export const runVerifier = (runRule) => {
  const repoPath = process.argv[2];
  if (!repoPath) {
    console.error(`usage: ${process.argv[1].split("/").pop()} <repo-path>`);
    process.exit(2);
  }

  let ts;
  try {
    ts = loadTypescript(repoPath);
  } catch (err) {
    console.error(`cannot load typescript from ${repoPath}: ${err.message}`);
    process.exit(2);
  }

  const offenders = runRule(ts, repoPath);
  if (offenders.length) {
    console.log(offenders.join("\n"));
    process.exit(1);
  }
  process.exit(0);
};
