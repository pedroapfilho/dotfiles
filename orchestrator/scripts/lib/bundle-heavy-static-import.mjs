#!/usr/bin/env node
// AST scan: flag "use client" files that statically import known-heavy packages
// AND aren't dynamic-imported anywhere via basename match.
//
// Standards.md § Bundle Optimization says heavy modules (tiptap, leaflet,
// chart libs) must be loaded via next/dynamic. The check is heuristic:
//
//   Pass 1: collect basenames appearing in `dynamic(() => import("path"))`
//   Pass 2: a "use client" file with heavy static imports is a real offender
//           only if its own basename isn't in that set
//
// This means a wrapper like `packages/ui/src/components/map.tsx` is fine if
// some app does `dynamic(() => import("@repo/ui/components/map"))`. False
// negatives are possible (basename collisions, ad-hoc consumers); false
// positives drop near zero in practice.

import { readFileSync } from "node:fs";
import { walkSource, parseTsx, runVerifier } from "./ast-helpers.mjs";

const HEAVY_PATTERNS = [
  /^@tiptap\//,
  /^leaflet$/,
  /^react-leaflet/,
  /^recharts$/,
  /^chart\.js$/,
  /^react-chartjs-2$/,
];

const isHeavy = (specifier) => HEAVY_PATTERNS.some((p) => p.test(specifier));

const isTsx = (name) => name.endsWith(".tsx");
const isJsTs = (name) =>
  /\.(?:tsx?|jsx?|mjs|cjs)$/.test(name) && !name.endsWith(".d.ts");

const fileBasename = (path) =>
  path.split("/").pop().replace(/\.(?:tsx?|jsx?|mjs|cjs)$/, "");

const hasUseClientDirectiveText = (src) =>
  /^\s*(?:['"])use client(?:['"])/.test(src);

const hasUseClientDirective = (ts, sf) => {
  for (const stmt of sf.statements) {
    if (
      stmt.kind === ts.SyntaxKind.ExpressionStatement &&
      stmt.expression.kind === ts.SyntaxKind.StringLiteral
    ) {
      if (stmt.expression.text === "use client") return true;
      continue; // another directive
    }
    break;
  }
  return false;
};

const findHeavyStaticImports = (ts, sf) => {
  const offenders = [];
  for (const stmt of sf.statements) {
    if (stmt.kind !== ts.SyntaxKind.ImportDeclaration) continue;
    if (stmt.importClause?.isTypeOnly) continue;
    const specifier = stmt.moduleSpecifier;
    if (specifier?.kind !== ts.SyntaxKind.StringLiteral) continue;
    if (!isHeavy(specifier.text)) continue;
    const { line } = sf.getLineAndCharacterOfPosition(stmt.getStart(sf));
    offenders.push({ line: line + 1, specifier: specifier.text });
  }
  return offenders;
};

// Extract basenames from `dynamic(() => import("…"))`. Handles arrow bodies
// that are either an expression (`=> import(...)`) or a block with a single
// `return import(...)`.
const collectDynamicBasenames = (ts, sf, set) => {
  const extractFromImportCall = (call) => {
    const arg = call.arguments?.[0];
    if (arg?.kind === ts.SyntaxKind.StringLiteral) {
      set.add(fileBasename(arg.text));
    }
  };

  const visit = (node) => {
    if (
      node.kind === ts.SyntaxKind.CallExpression &&
      node.expression.kind === ts.SyntaxKind.Identifier &&
      node.expression.text === "dynamic" &&
      node.arguments.length >= 1
    ) {
      const arg = node.arguments[0];
      if (arg.kind === ts.SyntaxKind.ArrowFunction) {
        const body = arg.body;
        if (
          body.kind === ts.SyntaxKind.CallExpression &&
          body.expression.kind === ts.SyntaxKind.ImportKeyword
        ) {
          extractFromImportCall(body);
        } else if (body.statements) {
          for (const s of body.statements) {
            if (
              s.kind === ts.SyntaxKind.ReturnStatement &&
              s.expression?.kind === ts.SyntaxKind.CallExpression &&
              s.expression.expression.kind === ts.SyntaxKind.ImportKeyword
            ) {
              extractFromImportCall(s.expression);
            }
          }
        }
      }
    }
    ts.forEachChild(node, visit);
  };
  ts.forEachChild(sf, visit);
};

runVerifier((ts, repoPath) => {
  // Pass 1: collect basenames that are dynamic-imported anywhere.
  const dynamicBasenames = new Set();
  for (const file of walkSource(repoPath, isJsTs)) {
    const src = readFileSync(file, "utf8");
    if (!src.includes("dynamic(")) continue;
    const sf = parseTsx(ts, file);
    collectDynamicBasenames(ts, sf, dynamicBasenames);
  }

  // Pass 2: heavy imports in client files that AREN'T dynamic-import targets.
  const offenders = [];
  for (const file of walkSource(repoPath, isTsx)) {
    const src = readFileSync(file, "utf8");
    if (!hasUseClientDirectiveText(src)) continue;
    if (dynamicBasenames.has(fileBasename(file))) continue;
    const sf = parseTsx(ts, file);
    if (!hasUseClientDirective(ts, sf)) continue;
    for (const { line, specifier } of findHeavyStaticImports(ts, sf)) {
      offenders.push(`${file.replace(repoPath + "/", "")}:${line} (${specifier})`);
    }
  }
  return offenders;
});
