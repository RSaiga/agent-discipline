---
language: en
diff_base: main
code: ["*.ts", "*.tsx"]
examples: typescript    # language pack under the kit's examples/: typescript | rust | go | python | java | php | ruby | csharp | none
lenses:
  structure:
    catalog: docs/refactoring.md
    catalog_auto_loaded: false
tdd:
  suites:
    - name: unit
      all: npm test
      one: npx vitest run <path> -t "<name>"
      speed: fast
  checks: none
  tests:
    - kind: unit
      path: tests/**/*.test.ts
      example: tests/example.test.ts
  known_failures: none
  hooks: none
  rules: none
  acceptance: none
---

# Project notes

Free-form notes about this project for the procedures to read when they point here.
