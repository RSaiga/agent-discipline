# review — 観点で変更を読む / Review a change through the lenses

`discipline.md` の「観点の約束」のとおり、読むだけで進める。直すことはしない（直すのは refactor の手順の仕事）。
Read-only throughout. Fixing is not part of review.

## 1. 対象を決める / Scope

- 呼び出しでファイルかディレクトリが指定されたら、それを対象にする。
- 指定がなければ、作業中の変更を対象にする（コミット済み・未ステージ・ステージ済みを合わせたもの）。
  設定を読んだ次の往復で、次の 3 つを**まとめて**行う:
  - `config.yaml` の観点ごとに `lenses/<観点>.md` を読む。
  - 観点ごとの基準のファイル（`profile.md` の `lenses.<観点>.catalog`）を読む。`catalog_auto_loaded: true` の観点は除く。
  - 次の 1 つのコマンドを実行する:
  ```
  git diff --name-only <diff_base>...HEAD; echo ---; git diff --name-only; echo ---; git diff --name-only --cached; echo ---; git diff <diff_base>
  ```
  If no target is given, review the working change. In the turn after reading the configuration, read the lens files and their catalogs (unless auto-loaded) and run the one command above, all together.
- `profile.md` の `code` に当てはまるファイルだけを残す。
- **変更した行を中心に見る。** 周りの文脈は読んでよいが、変更と関係のない既存のコードは指摘しない。
  Focus on changed lines; never flag untouched code.
- 対象が 0 件なら、そう報告して `## LENS CLEAN` で終える。

## 2. 観点を実行する / Run the lenses

`config.yaml` の `lenses` の順に、`lenses/<観点>.md` を読んで実行する。今の版の `runner` は `inline`（同じ文脈で順に）だけ。
Run each lens in `config.yaml` order by reading `lenses/<lens>.md`, inline.

## 3. まとめる / Summarize

観点の指摘のあとに、次を書く:

- 観点ごと、優先度ごとの件数
- 「挙動を変えずに直せるもの」と「設計の判断が要るもの」の区別
- 指摘が 0 件なら「構造的な指摘なし」のように**はっきり書く**。無理に絞り出さない。
  Say plainly when there is nothing to report; don't squeeze out findings.

最後の行は、すべての観点の合計で `## LENS CLEAN` か `## LENS FINDINGS <件数>`。
The last line is `## LENS CLEAN` or `## LENS FINDINGS <total>`.
