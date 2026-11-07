# agent-discipline

AI コーディングエージェントに、開発の規律を持たせるキット。Claude Code と Codex のプラグインとして動く。
中心は **観点チェック（lenses）** で、変更を決まった観点で読み、名前の付いた指摘と次の一手を返す。TDD などの **進め方（flows）** は、その上に乗る。

A kit that gives AI coding agents development discipline, as a plugin for Claude Code and Codex.
At its core are **lenses**: read a change from a fixed perspective and return named findings with a next move. **Flows** such as TDD build on them.

- どのプロジェクトの事実（テストのコマンド、置き場所、規約）も推測しない。プロジェクトに置いた `profile.md` から読み、足りなければ止まる。
  Never guesses project facts; reads them from the project's `profile.md` and stops when something is missing.
- 変えるのは、bench で結果が同じまま費用が下がったときだけ（`bench/criteria.md`）。
  A change is adopted only when the bench shows the same results at a lower cost.

## できること / What it does today

| 入口 / Entry | すること / What it does |
|---|---|
| `init` | プロジェクトを読んで `.agent-discipline/` の設定を下書きし、了承を得てから書く / Drafts the project settings and writes them after you agree |
| `review` | 観点で読む（structure・security・concurrency・isolation・acceptance）。対象は作業中の変更、ブランチか範囲、プルリクエストの URL、ファイルかディレクトリ。読むだけ / Reviews through the lenses: the working change, a branch or range, a pull request URL, or files and directories. Read-only |
| `tdd-plan` | 変更のテストのリストを作る（モード、シナリオ、内側の項目、変わる既存のテスト）。大きな依頼は先にストーリーに分ける。承認のあとで書く / Plans the test list, splitting large requests into stories first; writes after approval |
| `tdd-cycle` | テストのリストが尽きるまで回す。単層なら red → green → コミット → refactor、二重ループならシナリオごとに外側と内側を回す / Runs the TDD loop until the list is done, single layer or double loop |
| `tdd-accept` | 二重ループの外側の 1 手: 受け入れシナリオを書いて振る舞いで落とす、または走らせて緑なら閉じる / One outer-loop step: write the acceptance scenario and watch it fail, or run it and close it when green |
| `tdd-red` `tdd-green` `tdd-refactor` `tdd-commit` | TDD の 1 段階だけを行う / Runs one TDD stage |
| `retro` | 意図・結果・止まった箇所（と対策）を `findings.md` に残す。`track` で対策が効いたかを判定する / Records a retrospective; with `track`, judges whether countermeasures worked |

TDD は、外側の受け入れテストを持たない **単層** と、受け入れテストを外側に置く **二重ループ** を扱う。どちらも `tdd-cycle` で通しで回せ、段階ごとの入口でも回せる。
TDD runs the single layer and the double loop, end to end with `tdd-cycle` or stage by stage.

**観点 / Lenses**

| 観点 / Lens | 見るもの / What it checks |
|---|---|
| structure | プロジェクトのリファクタリングのカタログ（無ければキットの汎用のカタログ）の code smell / code smells from the project's (or the kit's starter) catalog |
| security | 認可・テナント分離・入力の境界・内部の漏れ・秘密・注入・外からの呼び出しの検証（SEC-1〜7）/ authorization, tenancy, input bounds, leaks, secrets, injection, webhook checks |
| concurrency | 確かめてから書くまでの競合・冪等性・トランザクション・複数インスタンス・共有の状態など（CON-1〜8）/ races, idempotency, transactions, shared state |
| isolation | データが混ざらないか: テナントの絞り込み・またぐ集計・キー・非同期の文脈・存在の漏れ、テスト同士のデータ・共有の状態・並列の取り合い（ISO-1〜8）/ tenant isolation and test isolation |
| acceptance | 緑になったシナリオの約束を、実装が本当に守っているか。書き手の結論を渡さず新しい文脈で読む / whether the implementation keeps a green scenario's promise, judged in a fresh context |

acceptance は `tdd-accept` がシナリオを閉じる前にかけ、破れていれば内側の項目に戻す。security と concurrency の確信度「高」には、破れる入力か壊れる順番を必ず添える。
`config.yaml` で選べるもの: `runner`（`inline` 既定・`subagent`・`command`）、`router`（`none` 既定・`inert`）、`backlog`（`none` 既定・`file`）。
The acceptance lens runs before a scenario closes. High-confidence security/concurrency findings always come with a breaking input or interleaving.
`runner: command` runs lenses through another CLI, e.g. Codex: `runner_command: ["codex", "exec", "--ephemeral", "--sandbox", "read-only", "-C", "{root}"]`
(the prompt goes on stdin).

どの入口も自動では起動しない。明示的に呼んだときだけ動く。 / No entry starts on its own; each runs only when invoked.

## 入れる / Install

**Claude Code**
```
claude plugin marketplace add RSaiga/agent-discipline
claude plugin install agent-discipline@agent-discipline
```
呼び出し / Invoke: `/agent-discipline:review`

**Codex**
```
codex plugin marketplace add RSaiga/agent-discipline
codex plugin add agent-discipline@agent-discipline
```
呼び出し / Invoke: `$agent-discipline:review`（名前空間が要る / the namespace is required）

**更新 / Update**

| ツール / Tool | コマンド / Commands |
|---|---|
| Claude Code | `claude plugin marketplace update agent-discipline` → `claude plugin update agent-discipline@agent-discipline` → 再起動 / restart |
| Codex | `codex plugin marketplace upgrade agent-discipline` |

## プロジェクトで使う / Use it in a project

1. プロジェクトで `init` を呼ぶ。下書きを見て、足りない項目を埋めてから了承する。
   Invoke `init` in the project, review the draft, fill what is missing, and agree.
2. 個人で使うなら、`.git/info/exclude` に `/.agent-discipline/` を足す。チームで共有するなら、コミットする。
   For personal use, add `/.agent-discipline/` to `.git/info/exclude`; to share with the team, commit it.
3. `review` や `tdd-cycle` を呼ぶ。設定が無いプロジェクトでは、何もせずに `init` を案内して止まる。
   Invoke `review` or `tdd-cycle`. Without settings, an entry points to `init` and stops.

プロジェクトに置くもの / What lives in the project:

```
<project>/.agent-discipline/
├── profile.md      # このプロジェクトの事実: 言語、差分の基準、観点の基準（リファクタリングのカタログ）、テストのスイート・置き場所・既知の失敗など
│                   # project facts: language, diff base, lens catalogs, test suites, test locations, known failures
├── config.yaml     # キットの動かし方: runner、使う観点、コミットの方針と言語
│                   # how the kit runs: runner, lenses, commit policy and language
├── lists/          # TDD のテストのリスト（ブランチごと）。コミットには入れない / per-branch TDD test lists, never committed
├── backlog.md      # backlog: file のとき、tdd-plan が分けたストーリー / stories tdd-plan split out, with backlog: file
├── refactoring.md  # プロジェクトにカタログが無いとき、init が置くキットの汎用のカタログ / the kit's starter catalog, when the project has none
└── findings.md     # retro の記録 / retro's log
```

項目の意味は `templates/` の雛形と、`procedures/discipline.md`・`procedures/tdd.md` の表にある。
The keys are described by the templates in `templates/` and the tables in `procedures/discipline.md` and `procedures/tdd.md`.

**規律の優先順位 / Precedence:** その場のユーザーの指示 → `config.yaml` → プロジェクトのルール → キットの規律。
The user's instruction in the moment, then `config.yaml`, then the project's rules, then the kit.

## 仕組み / How it is built

```
skills/       入口のスキル。短く、procedures/ の手順を読んで実行するだけ / thin entries that read and run a procedure
procedures/   手順の本文（共通の規律、review、TDD の各段階など）/ the procedures
lenses/       観点の本文 / the lenses
agents/       観点を新しい文脈で動かす担当（Claude 用）/ fresh-context lens runners (Claude)
examples/     言語パック（直し方の見本。TypeScript・Rust・Go・Python・Java/Kotlin・PHP・Ruby・C#）/ language packs (remedy examples)
templates/    profile.md と config.yaml の雛形 / templates for the project settings
bench/        費用と結果を測る仕組み / the measurement harness
```

- 手順と観点の本文には、ツール固有の言葉を書かない。ツールの違いは、入口の 1 行（プラグインの根元の見つけ方）と、ツールごとの設定ファイルだけに置く。
  Procedures and lenses stay tool-neutral; tool differences live only in one line of each entry and in per-tool config files.
- 手順は、互いに依存しない読み込みを 1 往復にまとめ、検索で絞ってから要るファイルだけを開く。往復の数と、ファイルを開いたときに読み込まれる規約が、費用の大半を決めるため。
  Procedures batch independent reads and search before opening files: round trips and folder-scoped rules pulled in by opening files dominate the cost.

## bench

`bench/run.sh` は、導入先のリポジトリを固定のコミットで複製し直し、同じ課題を版ごとに交互に（AB/BA）走らせて、費用・往復・結果を記録する。
`bench/grade.sh` は、指摘の名前と場所、起動しなかったこと、TDD の順番（テストが落ちてから実装を変えたか）を採点する。
採用の基準は `bench/criteria.md`。導入先の課題と結果は `bench/local/` に置き、公開しない。

`bench/run.sh` re-clones the target repository at a fixed commit and runs the same task per version in alternating order, recording cost, turns and outcome.
`bench/grade.sh` grades findings by name and location, non-invocation, and TDD order (did a test fail before the code changed).
The adoption criteria are in `bench/criteria.md`. Target-specific tasks and results stay in `bench/local/`, unpublished.

```
bench/tests/flow.sh        # run.sh の通し（偽の CLI）/ end-to-end check with a fake CLI
bench/tests/tdd-order.sh   # TDD の順番の採点 / the TDD order grader
bench/tests/outer-order.sh # 外側のループの順番の採点 / the outer-loop order grader
bench/tests/subagent-must.sh # 新しい文脈の担当の返事の採点 / grading what a fresh-context lens returned
bench/codex-stream.py      # Codex の出力を採点が読む形にする（variant の driver が codex のとき）/ converts Codex events for the grader
bench/fixtures/            # 外側の段階を確かめる練習用のプロジェクト / a practice project for the outer-loop stages
```

## 計画 / Plan

進める順番、各段階の完了の判定、決めたことと測った結果は `PLAN.md` にある。
The phases, their completion criteria, decisions and measured results are in `PLAN.md`.

## 貢献 / Contributing

Issue とプルリクエストを歓迎します。`CONTRIBUTING.md` を見てください。`main` への変更はプルリクエストだけで、`bench/tests` が GitHub Actions で通る必要があります。
Issues and pull requests are welcome; see `CONTRIBUTING.md`. `main` changes only through pull requests, with `bench/tests` passing in GitHub Actions.

## ライセンス / License

MIT
