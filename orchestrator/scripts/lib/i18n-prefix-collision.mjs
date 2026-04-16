#!/usr/bin/env node
// AST scan: detect i18n namespace-prefix collision.
//
//   const t = useTranslations("advertise");
//   t("advertise.foo");  // resolves to advertise.advertise.foo — usually missing
//
// Standards.md § i18n: "When calling useTranslations('<scope>'), keys must NOT
// repeat the scope prefix."
//
// Strategy: per source file, walk top-level statements + descend into function
// bodies; track `const X = useTranslations("<ns>")` bindings in a flat scope
// (good enough for typical component code), then flag `X("<ns>.…")` calls.

import { walkSource, parseTsx, runVerifier } from "./ast-helpers.mjs";

const getStringArg = (ts, callExpr) => {
  const arg = callExpr.arguments?.[0];
  if (
    arg?.kind === ts.SyntaxKind.StringLiteral ||
    arg?.kind === ts.SyntaxKind.NoSubstitutionTemplateLiteral
  ) {
    return arg.text;
  }
  return null;
};

const findUseTranslationsBindings = (ts, sourceFile) => {
  // Map<bindingName, namespace>
  const bindings = new Map();
  const visit = (node) => {
    if (
      node.kind === ts.SyntaxKind.VariableDeclaration &&
      node.name?.kind === ts.SyntaxKind.Identifier &&
      node.initializer?.kind === ts.SyntaxKind.CallExpression
    ) {
      const init = node.initializer;
      const calleeName =
        init.expression.kind === ts.SyntaxKind.Identifier
          ? init.expression.text
          : init.expression.kind === ts.SyntaxKind.PropertyAccessExpression
            ? init.expression.name?.text
            : null;
      if (calleeName === "useTranslations" || calleeName === "getTranslations") {
        const ns = getStringArg(ts, init);
        if (ns) bindings.set(node.name.text, ns);
      }
    }
    ts.forEachChild(node, visit);
  };
  ts.forEachChild(sourceFile, visit);
  return bindings;
};

const findCollisions = (ts, sourceFile, bindings) => {
  const offenders = [];
  const visit = (node) => {
    if (
      node.kind === ts.SyntaxKind.CallExpression &&
      node.expression.kind === ts.SyntaxKind.Identifier
    ) {
      const callee = node.expression.text;
      const ns = bindings.get(callee);
      if (ns) {
        const key = getStringArg(ts, node);
        if (key && (key === ns || key.startsWith(`${ns}.`))) {
          const { line } = sourceFile.getLineAndCharacterOfPosition(
            node.expression.getStart(sourceFile),
          );
          offenders.push({ line: line + 1, callee, ns, key });
        }
      }
    }
    ts.forEachChild(node, visit);
  };
  ts.forEachChild(sourceFile, visit);
  return offenders;
};

const isSourceFile = (name) =>
  (name.endsWith(".tsx") || name.endsWith(".ts")) && !name.endsWith(".d.ts");

runVerifier((ts, repoPath) => {
  const offenders = [];
  for (const file of walkSource(repoPath, isSourceFile)) {
    const sf = parseTsx(ts, file);
    const bindings = findUseTranslationsBindings(ts, sf);
    if (bindings.size === 0) continue;
    for (const { line, callee, ns, key } of findCollisions(ts, sf, bindings)) {
      offenders.push(
        `${file.replace(repoPath + "/", "")}:${line} (${callee}("${key}") with ns="${ns}")`,
      );
    }
  }
  return offenders;
});
