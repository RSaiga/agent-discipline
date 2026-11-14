# discipline — 共通の規律 / Shared discipline

どの入口からも最初に読む。ここに書いた条件を満たさないときは、先に進まずに止まる。
Every entry reads this first. If a condition below is not met, stop.

**互いに依存しない読み込みとコマンドは、1 回の往復でまとめて行う。** 往復のたびに、それまでの文脈をすべて読み直すことになる。
Batch independent reads and commands into one turn; every turn re-reads the whole context.

**読む量を絞る。** 場所を探すときは、まず検索（grep の類い）で絞り、要るファイルだけを開く。周りを確かめるときは、前後の行を付けた検索で足りることが多い。
ファイルを開くと、そのフォルダを対象にしたプロジェクトの規約がまとめて読み込まれることがある。一度読んだ規約や手順は、読み直さない。
Search first and open only what you need — opening a file can pull in the project's folder-scoped rules. Never re-read a rule or procedure already read.

## 動く条件 / Activation

1. **プロジェクトの根元を決める。** `git rev-parse --show-toplevel` の結果。Git の管理外なら現在のディレクトリ。
   サブディレクトリで呼ばれても、根元のものを使う。worktree では、その worktree の根元を使う。
   The project root is `git rev-parse --show-toplevel`, or the current directory outside Git.
2. **`<根元>/.codence/profile.md` を読む。** 無ければ「このプロジェクトはまだ設定されていない。`init` で設定できる」と伝えて止まる。
   No profile → say so, point to `init`, and stop.
3. **`<根元>/.codence/config.yaml` を読む。** 無ければ 2 と同じく止まる。
4. **必須の項目を確かめる。** 欠けている・値が読めない項目があれば、**どのファイルのどの項目か**を示して止まる。推測で補わない。
   Missing or unreadable required keys → name the file and key, and stop. Never fill them in by guessing.

| ファイル | 必須の項目 | 値 | 要る入口 |
|---|---|---|---|
| `profile.md`（先頭の YAML） | `language` | 報告に使う言語（例 `ja`, `en`） | すべて |
| | `diff_base` | 差分の基準にするブランチ | すべて |
| | `code` | 実装のファイルとみなすパターンの一覧 | すべて |
| | `lenses.<観点>.catalog` | `config.yaml` の `lenses` に挙げた観点ごとの、判定の基準のファイル（根元からの相対パス）。`structure` だけ必須。`security`・`concurrency`・`isolation` はプロジェクトが足す項目（無くてよい。汎用の項目は観点のファイルにある）。`acceptance` は要らない（基準はシナリオの出典） | すべて |
| | `tdd.suites` | テストのスイートの一覧（`tdd.md` の「プロジェクトの情報」） | TDD の入口、`refactor` |
| `config.yaml` | `runner` | `inline`・`subagent`・`command`（`review.md`「観点を実行する」。`subagent` は任意で `runner_mode`（`parallel`・`combined`、既定は `parallel`）と `runner_model`、`command` は必須の `runner_command`（引数の配列）と任意の `runner_mode`） | すべて |
| | `lenses` | 使う観点の一覧（`structure`・`acceptance`・`security`・`concurrency`・`isolation`）。`[]` なら観点を使わない（`review` は観点が無いと伝えて止まる）。`acceptance` は常に新しい文脈で動かす（`runner` に関わらない） | すべて |
| | `commit` | `never` / `on-request` / `on-green` | すべて |
| | `commit_language` | コミットメッセージの言語（例 `ja`, `en`） | TDD の入口 |

任意の項目: `profile.md` の `examples`（言語パックの名前か、その一覧。`typescript`・`rust`・`go`・`python`・`java`・`php`・`ruby`・`csharp`・`none`）、`config.yaml` の `backlog`（`file`・`none`。既定は `none`。`plan.md`「ストーリーに分ける」）、`router`（`none`・`inert`。既定は `none`。`review.md`「観点を選ぶ」）、`commit_style`（`conventional`・`history`。既定は `conventional`。`commit.md`）、`second_opinion_commands`（引数の配列の一覧。`--second` で使う別の AI の候補。`second-opinion.md`）。言語パック（キットの `examples/`）は、無ければ `none`。
Optional: the profile's `examples` names one language pack or a list of them; absent means none.

`profile.md` の YAML の後ろの本文は、このプロジェクトについての自由なメモ。手順が参照を指示したときに読む。
The prose after the profile's YAML is free-form project notes; read it when a procedure says so.

## 規律の優先順位 / Precedence

1. ユーザーのその場の指示 / The user's instruction in the moment
2. `config.yaml`
3. プロジェクトのルール（`profile.md` が指すもの） / Project rules the profile points to
4. このキットの規律 / This kit's discipline

## 観点の約束 / The lens contract

- **読むだけ。** 観点を実行しているあいだは、ファイルを書かない。Git の状態（ブランチ、index、コミット、stash）を変えない。書き込みをするコマンドを実行しない。
  Lenses are read-only: no file writes, no Git state changes, no writing commands.
- **基準のファイルが自動で読み込まれるなら、自分で開かない。** `lenses.<観点>.catalog_auto_loaded: true` のときは、
  先に対象の変更したファイルを 1 つ開く（どのみち読むもので、開いたときにカタログが読み込まれる）。そのあとも文脈に無ければ、そのときだけ開く。
  If the catalog is auto-loaded, open a changed file first (you need it anyway and it pulls the catalog in);
  open the catalog only if it is still not in context.
- **返し方を固定する。** 観点の手順が決めた見出しの形で指摘を書き、最後の行を `## LENS CLEAN`（指摘 0 件）か `## LENS FINDINGS <件数>` にする。
  `acceptance` はこれに `## LENS UNVERIFIED <件数>` と `## LENS STOPPED` が加わる（`lenses/acceptance.md`）。
  End with `## LENS CLEAN` or `## LENS FINDINGS <n>`.
- 報告は `profile.md` の `language` で書く。 / Report in the profile's `language`.
