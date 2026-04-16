#!/usr/bin/env node
// AST scan: flag useEffect/useCallback/useMemo/useLayoutEffect calls whose
// dependency array contains an identifier named `field`. The @tanstack/react-form
// `field` object is unstable across renders — referencing it in a dep array
// causes re-subscription on every render. Standards.md § Forms forbids this.

import { walkSource, parseTsx, runVerifier } from "./ast-helpers.mjs";

const TRACKED_HOOKS = new Set([
  "useEffect",
  "useCallback",
  "useMemo",
  "useLayoutEffect",
  "useInsertionEffect",
]);

const isTrackedHookCall = (ts, node) => {
  if (node.kind !== ts.SyntaxKind.CallExpression) return false;
  const callee = node.expression;
  // `useEffect(...)` or `React.useEffect(...)`
  if (callee.kind === ts.SyntaxKind.Identifier) {
    return TRACKED_HOOKS.has(callee.text);
  }
  if (
    callee.kind === ts.SyntaxKind.PropertyAccessExpression &&
    callee.name?.kind === ts.SyntaxKind.Identifier
  ) {
    return TRACKED_HOOKS.has(callee.name.text);
  }
  return false;
};

const findFieldDeps = (ts, sourceFile) => {
  const offenders = [];
  const visit = (node) => {
    if (isTrackedHookCall(ts, node) && node.arguments.length >= 2) {
      const depsArg = node.arguments[1];
      if (depsArg.kind === ts.SyntaxKind.ArrayLiteralExpression) {
        for (const element of depsArg.elements) {
          if (
            element.kind === ts.SyntaxKind.Identifier &&
            element.text === "field"
          ) {
            const { line } = sourceFile.getLineAndCharacterOfPosition(
              element.getStart(sourceFile),
            );
            offenders.push(line + 1);
            break;
          }
        }
      }
    }
    ts.forEachChild(node, visit);
  };
  ts.forEachChild(sourceFile, visit);
  return offenders;
};

const isTsx = (name) => name.endsWith(".tsx");

runVerifier((ts, repoPath) => {
  const offenders = [];
  for (const file of walkSource(repoPath, isTsx)) {
    const sf = parseTsx(ts, file);
    for (const line of findFieldDeps(ts, sf)) {
      offenders.push(`${file.replace(repoPath + "/", "")}:${line}`);
    }
  }
  return offenders;
});
