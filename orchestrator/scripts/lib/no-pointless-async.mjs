#!/usr/bin/env node
// AST scan: find Server Component files (page/layout/template/default) whose
// default-exported function is `async` but contains no `await` in its own body.
// Nested function awaits don't count — they belong to a different scope.
//
// Usage: node no-pointless-async.mjs <repo-path>
// Exits 0 if clean, 1 if offenders printed to stdout (one "path:line" per line).

import { createRequire } from "node:module";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const repoPath = process.argv[2];
if (!repoPath) {
  console.error("usage: no-pointless-async.mjs <repo-path>");
  process.exit(2);
}

let ts;
try {
  const require = createRequire(join(repoPath, "package.json"));
  ts = require("typescript");
} catch (err) {
  console.error(`cannot load typescript from ${repoPath}: ${err.message}`);
  process.exit(2);
}

const TARGET_FILES = new Set(["page.tsx", "layout.tsx", "template.tsx", "default.tsx"]);
const SKIP_DIRS = new Set(["node_modules", ".next", ".turbo", "dist", "generated", ".git"]);

function* walk(dir) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      yield* walk(full);
    } else if (TARGET_FILES.has(entry.name)) {
      yield full;
    }
  }
}

function hasOwnAwait(fnNode) {
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
    // Don't descend into nested function declarations — their awaits belong to a different scope.
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
}

function isAsync(node) {
  return node.modifiers?.some((m) => m.kind === ts.SyntaxKind.AsyncKeyword) ?? false;
}

function findDefaultExportedAsyncFn(sourceFile) {
  let target = null;
  const localFns = new Map();

  ts.forEachChild(sourceFile, (node) => {
    if (target) return;

    // Pattern 1: `export default async function Foo() {}`
    if (
      node.kind === ts.SyntaxKind.FunctionDeclaration &&
      node.modifiers?.some((m) => m.kind === ts.SyntaxKind.ExportKeyword) &&
      node.modifiers?.some((m) => m.kind === ts.SyntaxKind.DefaultKeyword) &&
      isAsync(node)
    ) {
      target = node;
      return;
    }

    // Track local fn declarations + arrow consts so we can resolve `export default Foo`.
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

  if (target) return target;

  // Pattern 2: `export default Foo` (referencing a local function/arrow).
  ts.forEachChild(sourceFile, (node) => {
    if (target) return;
    if (node.kind !== ts.SyntaxKind.ExportAssignment) return;
    const expr = node.expression;
    if (!expr) return;
    // Inline arrow / function expression: `export default async () => { ... }`
    if (
      (expr.kind === ts.SyntaxKind.ArrowFunction ||
        expr.kind === ts.SyntaxKind.FunctionExpression) &&
      isAsync(expr)
    ) {
      target = expr;
      return;
    }
    // Identifier referencing a local async fn
    if (expr.kind === ts.SyntaxKind.Identifier) {
      const local = localFns.get(expr.text);
      if (local && isAsync(local)) target = local;
    }
  });

  return target;
}

const appsDir = join(repoPath, "apps");
try {
  statSync(appsDir);
} catch {
  // No apps/ — nothing to check.
  process.exit(0);
}

const offenders = [];
for (const file of walk(appsDir)) {
  const src = readFileSync(file, "utf8");
  const sf = ts.createSourceFile(file, src, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
  const fn = findDefaultExportedAsyncFn(sf);
  if (!fn) continue;
  if (hasOwnAwait(fn)) continue;
  const { line } = sf.getLineAndCharacterOfPosition(fn.getStart(sf));
  offenders.push(`${file.replace(repoPath + "/", "")}:${line + 1}`);
}

if (offenders.length) {
  console.log(offenders.join("\n"));
  process.exit(1);
}
process.exit(0);
