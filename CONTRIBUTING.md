# Contributing / 貢献のしかた

Issue とプルリクエストを歓迎します。日本語でも英語でも構いません。
Issues and pull requests are welcome, in Japanese or English.

## Issue

- **不具合**: どの入口を呼び、何を期待し、何が起きたか。使ったツール（Claude Code / Codex）と版、`profile.md`・`config.yaml` の該当する部分。
  **Bug**: the entry you invoked, what you expected, what happened, the tool and version, and the relevant settings.
- **提案**: 何に困っているか（実際に起きたこと）を先に書く。直し方の案はそのあとで。
  **Proposal**: start from the problem you actually hit; the fix comes after.

## プルリクエスト / Pull requests

1. 1 つのプルリクエストに 1 つの目的。手順（`procedures/`）・観点（`lenses/`）を変えるなら、何がなぜ変わるかを書く。
   One purpose per pull request. When a procedure or lens changes, say what changes and why.
2. `bench/tests/*.sh` が通ること（GitHub Actions でも走る）。
   `bench/tests/*.sh` must pass (they also run in GitHub Actions).
3. 手順や観点の振る舞いを変えるなら、bench の結果を添える。採用の基準は `bench/criteria.md`（結果が同じかそれ以上で、費用が下がるなら採用）。
   測っていない変更は、測っていないと書く。
   Behaviour changes come with bench results; the adoption rule is in `bench/criteria.md`. Say so when something is unmeasured.
4. 本文（`procedures/`・`lenses/`・`examples/`・`templates/`・入口の本文）にツールの名前やローカルのパスを書かない。
   例は架空の題材で書き、実在の組織・製品・人の名前を出さない。
   Keep the bodies tool-neutral and free of local paths; write examples in a fictional domain, never naming real organizations, products or people.
5. 本文は日英併記（日本語の文のあとに英語の要約）。 / Bodies are bilingual: Japanese, then an English summary.

## 版 / Versions

手順・観点・入口を変えたら、`.claude-plugin/plugin.json`・`.claude-plugin/marketplace.json`・`.codex-plugin/plugin.json` の `version` を上げる。
Bump `version` in the three plugin manifests whenever procedures, lenses or entries change.
