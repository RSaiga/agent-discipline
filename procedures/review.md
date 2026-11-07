# review — 観点で変更を読む / Review a change through the lenses

`discipline.md` の「観点の約束」のとおり、読むだけで進める。直すことはしない（直すのは refactor の手順の仕事）。
Read-only throughout. Fixing is not part of review.

`config.yaml` の `lenses` が空（`[]`）なら、使う観点が無いと伝えて止まる。 / With no lenses configured, say so and stop.

## 1. 対象を決める / Scope

呼び出しの指定で、対象と読み方が 4 つに分かれる。 / The invocation picks one of four targets.

| 指定 | 対象 | 見るところ |
|---|---|---|
| なし | 作業中の変更（コミット済み・未ステージ・ステージ済みを合わせたもの） | 変更した行 |
| ブランチ名かコミットの範囲（`main..HEAD`・`HEAD~3..`・PR のブランチ） | その範囲の差分（実装したあとのレビュー） | 変更した行 |
| プルリクエストの URL | そのプルリクエストの差分（手元に取り込まずに読む） | 変更した行 |
| ファイルかディレクトリ | **そのコード全体**（コードのレビュー。変更に限らない） | ファイルのすべての行 |

- ブランチ名かコミットの範囲なら、下のコマンドの `<diff_base>` と作業中の差分の代わりに、その範囲の `git diff --name-only <範囲>` と `git diff <範囲>` を使う。
- プルリクエストの URL なら、URL から番号を取り、それを参照する名前に直す（`/pull/<番号>` は `pull/<番号>/head`、
  `/merge_requests/<番号>` は `merge-requests/<番号>/head`）。どちらの形でもなければ、ブランチ名か範囲で指定し直すよう伝えて止まる。
  `git remote -v` から、URL のホストとリポジトリに合うリモートを選ぶ（無ければ止まる）。次の 1 つのコマンドで取り込む:
  ```
  git fetch -q <リモート> <diff_base> && git fetch -q <リモート> <参照する名前> && git rev-parse FETCH_HEAD
  ```
  出てきたコミットを `<先頭>` として、範囲 `<リモート>/<diff_base>...<先頭>` で上の範囲と同じに読む。作業ツリーは変えない（checkout しない）。
  周りの文脈も作業ツリーではなく `git show '<先頭>:<パス>'` で読む（作業ツリーは別のブランチのことがある）。
  比べる先は `diff_base` と見なす。プルリクエストが別のブランチに向いているなら、要約にそう書き、範囲で指定し直せることを添える。
  For a pull/merge request URL, fetch its head ref without checking out, review `<remote>/<diff_base>...<head>`, and read context with `git show`, not the working tree.
- ファイルかディレクトリなら、差分ではなくファイルそのものを読む。`profile.md` の `code` に当てはまるファイルが 30 を超えるなら、
  分け方（フォルダごと、機能ごと）を示して止まる（一度に読むと、どの観点も浅くなる）。`acceptance` は対象にしない（リストのシナリオがあるときだけの観点）。
- 指定がなければ、作業中の変更を対象にする。
  設定を読んだ次の往復で、次の 3 つを**まとめて**行う（`router: inert` のときは 3 つ目のコマンドだけを先に実行し、観点のファイルと基準のファイルは
  2 で選んだ観点の分だけ、そのあとでまとめて読む。読んでから飛ばしても節約にならない）:
  - `config.yaml` の観点ごとに `lenses/<観点>.md` を読む。
  - 観点ごとの基準のファイル（`profile.md` の `lenses.<観点>.catalog`）を読む。`catalog_auto_loaded: true` の観点は除く。
    `profile.md` の `examples` が `none` 以外なら、挙げた言語パックごとに、キットの `examples/<言語>/<観点>.md` もあれば読む（直し方の見本。要件ではない）。
    言語パックが複数あるときは、対象のファイルの言語に合うものだけを読む（変更が TypeScript だけなら `typescript` だけ）。
  - 次の 1 つのコマンドを実行する（最後の行は作業ツリーの指紋。追跡外のファイルも含む）:
  ```
  git diff --name-only <diff_base>...HEAD; echo ---; git diff --name-only; echo ---; git diff --name-only --cached; echo ---; git ls-files --others --exclude-standard; echo ---; git diff <diff_base>; echo ---; { git diff HEAD; git diff --cached; git ls-files --others --exclude-standard -z | xargs -0 git hash-object; } | git hash-object --stdin
  ```
  If no target is given, review the working change. In the turn after reading the configuration, read the lens files and their catalogs (unless auto-loaded) and run the one command above, all together.
- `profile.md` の `code` に当てはまるファイルだけを残す。追跡外の新しいファイルも対象（中身は差分ではなくファイルとして読む）。
- **変更を対象にするときは、変更した行を中心に見る。** 周りの文脈は読んでよいが、変更と関係のない既存のコードは指摘しない。
  ファイルかディレクトリを対象にするときは、すべての行が対象。
  For a change, focus on changed lines and never flag untouched code; for files or directories, every line is in scope.
- 対象が 0 件なら、そう報告して `## LENS CLEAN` で終える。

## 2. 観点を選ぶ / Route

`config.yaml` の `router` が `inert` のときだけ行う（既定の `none` では、すべての観点を実行する）。観点のファイルを読む前に、1 の差分だけで決める。
- **security・concurrency・isolation を飛ばしてよいのは、変更したすべての行が次のどれかに当たるときだけ。** 1 行でも当たらなければ、すべて実行する。迷ったら実行する。
  - コメントか空行だけの変更。
  - テストのファイル（`tdd.tests` の置き場所）に、新しいテストのケースを足すだけ。共有の準備・環境変数・時刻・モジュールの変数・ファイルに触れない。
    この場合も `isolation` は飛ばさない（テスト同士のデータの独立は、この観点が見るもの）。
  - 1 つの関数の中だけで、名前を変えるだけ（ほかの字句は同じ）。
- `structure` は常に実行する。`acceptance` はリストで決まる（`router` に関わらない）。プロジェクトが足した項目（`catalog`）を持つ観点は飛ばさない。
- 飛ばした観点と、当たった条件を報告に書く（「飛ばした: security, concurrency — コメントだけの変更」）。飛ばした観点は `CLEAN` ではない。
Run only with `router: inert`: skip security, concurrency and isolation only when every changed line is a comment, a new test case that touches no
shared state (isolation still runs on test changes), or a rename inside one function; otherwise run everything. Report what was skipped and why; a skipped lens is not CLEAN.

## 3. 観点を実行する / Run the lenses

`config.yaml` の `runner` に従う。観点が読んでいるあいだ、誰も書かない。 / Nobody writes while lenses read.

- **`inline`**（既定）: `lenses` の順に、`lenses/<観点>.md` を読んで同じ文脈で実行する。
- **`subagent`**: 観点を新しい文脈で動かす。ツールに `lens-runner` の担当があればそれを、無ければ新しい文脈の担当を使う。
  渡すのは、観点のファイルの絶対パス・基準のファイル・見本のファイル・プロジェクトの根元・`diff_base`・対象のファイルの一覧（追跡外を含む）だけ。
  担当は差分を `git diff <diff_base>` で自分で読む（読むだけのコマンドに限る）。
  - `runner_mode: parallel`（既定）: 観点ごとに 1 つずつ、同時に起動する。
  - `runner_mode: combined`: 1 つの担当にすべての観点を渡す。返事は観点ごとに `### 観点: <名前>` の節に分け、節ごとに最後の行を書かせる。
  - `runner_model`: 担当のモデル。無ければ親と同じ。
  - 担当が起動できない・返事に最後の行が無い・形が違う観点は、`## LENS STOPPED` として扱う（`CLEAN` にしない）。
  - 担当の指摘は、見出しの形のまま回答に写す（要約して形を崩さない）。
- **`command`**: 観点を外のコマンドで動かす（別のツールの CLI など）。`runner_command` は引数の配列で、`{root}` だけを置き換える。
  渡すもの（`subagent` と同じ）をプロンプトにして、リポジトリの外の一時ファイルに書き、**標準入力**で渡す。プロンプトを引数に入れない。
  引数は要素ごとに引用して並べ、シェルの文字列に組み立て直さない。`runner_mode` は `subagent` と同じに扱う。
  10 分で終わらない・0 以外で終わる・最後の行が無い観点は `## LENS STOPPED`。`combined` では、頼んだ観点ごとに節がちょうど 1 つあることを確かめる。
  `command` runs each lens through `runner_command` (an argv array; only `{root}` is substituted) with the prompt on stdin, never in an argument.
  A timeout (10 min), a non-zero exit or a missing last line makes that lens STOPPED.
- **終わったら、1 のコマンドの指紋をもう一度とる。** 変わっていたら、結果を捨てて「読んでいるあいだに作業ツリーが変わった」と報告し、`## LENS STOPPED` で終える。
Run per `runner`: `inline` in this context; `subagent` in fresh contexts (parallel per lens, or combined with one section per lens).
A lens that fails to start or answers without its last line is STOPPED, never CLEAN. Re-take the snapshot afterwards; if it changed, discard.

`acceptance` だけは別に扱う。今のブランチのリスト（`tdd.md`「テストのリスト」）が無ければ、この観点は飛ばしてそう書く。
あれば、`[~]` か `[x]` のシナリオ（`[remove]` を除く）ごとに、`accept.md` の「受け入れの観点」の 1・2 のとおり新しい文脈で起動し、返事をそのまま並べる。
`acceptance` runs per scenario of the branch list in a fresh context (as in accept.md); with no list, skip it and say so.

## 4. まとめる / Summarize

観点の指摘のあとに、次を書く:

- 観点ごと、優先度ごとの件数と、観点ごとの最後の行
- 「挙動を変えずに直せるもの」と「設計の判断が要るもの」の区別
- security・concurrency・isolation の確信度「高」は正しさの問題として、**落ちるテストを書くところから**（`tdd-red`）直すことを勧める。「中」「低」は報告だけ。
  直すのはこの手順の仕事ではない（読むだけ）。 / High security/concurrency findings are correctness bugs: recommend starting from a failing test.
- 指摘が 0 件なら「構造的な指摘なし」のように**はっきり書く**。無理に絞り出さない。
  Say plainly when there is nothing to report; don't squeeze out findings.

最後の行は、実行した観点を合わせて 1 つ（飛ばした観点は、その前の行に「飛ばした: …」と書く）: どれかが `STOPPED` なら `## LENS STOPPED`、指摘があれば `## LENS FINDINGS <合計>`、
`UNVERIFIED` だけなら `## LENS UNVERIFIED <合計>`、それ以外は `## LENS CLEAN`。
The last line: STOPPED if any lens stopped, else FINDINGS <total>, else UNVERIFIED <total>, else CLEAN.
