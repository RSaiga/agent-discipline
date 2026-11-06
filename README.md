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
| `ad-init` | プロジェクトを読んで `.agent-discipline/` の設定を下書きし、了承を得てから書く / Drafts the project settings and writes them after you agree |
| `ad-review` | 作業中の変更を structure の観点（code smell）で読む。読むだけ / Reviews the working change through the structure lens. Read-only |
| `ad-plan` | 変更のテストのリストを作る（モード、シナリオ、内側の項目、変わる既存のテスト）。承認のあとで、リストだけを書く / Plans the test list; writes only the list, after approval |
| `ad-cycle` | テストのリストが尽きるまで、red → green → コミット → refactor を回す（単層） / Runs the single-layer TDD loop until the test list is done |
| `ad-accept` | 二重ループの外側の 1 手: 受け入れシナリオを書いて振る舞いで落とす、または走らせて緑なら閉じる / One outer-loop step: write the acceptance scenario and watch it fail, or run it and close it when green |
| `ad-red` `ad-green` `ad-refactor` `ad-commit` | TDD の 1 段階だけを行う / Runs one TDD stage |
| `ad-retro` | 意図・結果・止まった箇所を `findings.md` に残す / Records intent, result and where it stopped |

TDD は、外側の受け入れテストを持たない **単層** と、受け入れテストを外側に置く **二重ループ** を扱う。二重ループは今、段階ごとの入口（`ad-accept` → `ad-red` / `ad-green` → …）で回す。通しの `ad-cycle` で回せるのは単層だけ。
acceptance などの観点、ほかの runner は `PLAN.md` の順に足していく。
TDD runs the single layer and the double loop; the double loop runs stage by stage for now, and `ad-cycle` runs single-layer lists only.

どの入口も自動では起動しない。明示的に呼んだときだけ動く。 / No entry starts on its own; each runs only when invoked.

## 入れる / Install

**Claude Code**
```
claude plugin marketplace add RSaiga/agent-discipline
claude plugin install agent-discipline@agent-discipline
```
呼び出し / Invoke: `/agent-discipline:ad-review`

**Codex**
```
codex plugin marketplace add RSaiga/agent-discipline
codex plugin add agent-discipline@agent-discipline
```
呼び出し / Invoke: `$agent-discipline:ad-review`（名前空間が要る / the namespace is required）

**更新 / Update**

| ツール / Tool | コマンド / Commands |
|---|---|
| Claude Code | `claude plugin marketplace update agent-discipline` → `claude plugin update agent-discipline@agent-discipline` → 再起動 / restart |
| Codex | `codex plugin marketplace upgrade agent-discipline` |

## プロジェクトで使う / Use it in a project

1. プロジェクトで `ad-init` を呼ぶ。下書きを見て、足りない項目を埋めてから了承する。
   Invoke `ad-init` in the project, review the draft, fill what is missing, and agree.
2. 個人で使うなら、`.git/info/exclude` に `/.agent-discipline/` を足す。チームで共有するなら、コミットする。
   For personal use, add `/.agent-discipline/` to `.git/info/exclude`; to share with the team, commit it.
3. `ad-review` や `ad-cycle` を呼ぶ。設定が無いプロジェクトでは、何もせずに `ad-init` を案内して止まる。
   Invoke `ad-review` or `ad-cycle`. Without settings, an entry points to `ad-init` and stops.

プロジェクトに置くもの / What lives in the project:

```
<project>/.agent-discipline/
├── profile.md      # このプロジェクトの事実: 言語、差分の基準、観点の基準（リファクタリングのカタログ）、テストのスイート・置き場所・既知の失敗など
│                   # project facts: language, diff base, lens catalogs, test suites, test locations, known failures
├── config.yaml     # キットの動かし方: runner、使う観点、コミットの方針と言語
│                   # how the kit runs: runner, lenses, commit policy and language
├── lists/          # TDD のテストのリスト（ブランチごと）。コミットには入れない / per-branch TDD test lists, never committed
└── findings.md     # ad-retro の記録 / ad-retro's log
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
bench/fixtures/            # 外側の段階を確かめる練習用のプロジェクト / a practice project for the outer-loop stages
```

## 計画 / Plan

進める順番、各段階の完了の判定、決めたことと測った結果は `PLAN.md` にある。
The phases, their completion criteria, decisions and measured results are in `PLAN.md`.

## ライセンス / License

MIT
