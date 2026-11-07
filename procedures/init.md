# init — プロジェクトに設定を置く / Set up a project

書いてよいのは `<根元>/.agent-discipline/` の中だけ。Git の設定、`.gitignore`、ほかのファイルは変えない。
Write only inside `<root>/.agent-discipline/`. Never change Git config, `.gitignore`, or any other file.

1. **根元を決める**（`discipline.md` の「動く条件」の 1）。
2. **すでにあるか確かめる。** `profile.md` か `config.yaml` があれば、中身を示し、上書きするかをユーザーに聞く。答えがなければ止まる。
   If either file exists, show it and ask before overwriting.
3. **下書きを作る。** 根元の `templates/` の雛形を元に、プロジェクトを読んで値を埋める。
   - `language`: これまでのやりとりの言語。
   - `diff_base`: 既定のブランチ（`git symbolic-ref refs/remotes/origin/HEAD` など）。
   - `code`: リポジトリに実際にある実装の拡張子。
   - `examples`: リポジトリにある言語のうち、キットの `examples/` に言語パックがあるものをすべて、一覧で（例 `[rust, typescript]`。`typescript`・`rust`・`go`・`python`・`java`・`php`・`ruby`・`csharp`。Kotlin は `java`）。1 つも無ければ `none`。
   - `lenses.structure.catalog`: プロジェクトのリファクタリングの規約やカタログ。推測で作らない。
     見つからなければ、キットの `templates/refactoring.md`（汎用のカタログ）を `.agent-discipline/refactoring.md` に置いてそこを指す案を、
     下書きに含めて聞く。断られたら `catalog` は空のまま、`config.yaml` の `lenses` を `[]` にし、構造の観点が働かないことを伝える。
     With no catalog in the project, offer to copy the kit's starter catalog into `.agent-discipline/`; if declined, set `lenses: []`.
   - `lenses.structure.catalog_auto_loaded`: その規約が、フォルダを対象にして自動で読み込まれる設定になっているなら `true`。分からなければ `false`。
   - `tdd.suites`: プロジェクトが実際に使っているテストのコマンド（README、タスクランナー、パッケージの scripts など）。全体と 1 本に絞る形を、試さずに書けるものだけ書く。
     `speed` は分からなければ書かず、そのことを伝える（`tdd-cycle` が最初の全体の実行で決める。単独の段では `slow` として扱う）。
   - `tdd.tests`: 既存のテストの置き場所と、倣うお手本にできるテストのファイル。
   - `tdd.checks`・`tdd.known_failures`・`tdd.hooks`・`tdd.rules`: プロジェクトから読み取れたものだけ。無ければ `none`。既知の失敗は推測で書かない。
   - `tdd.acceptance`・`tdd.stack`: 受け入れテスト（外からスタックを動かして確かめるテスト）があれば、`tdd.md`「プロジェクトの情報」の表のキーを
     すべて埋める。無ければ `acceptance: none`。とくに次を、走らせ方のスクリプトや設定を読んで確かめる:
     - `format` に、進行中のシナリオの印（タグなど）と、それが既定の実行から外れる仕組みを書く。
     - `run_one` は、その道具が実際に絞れる単位（名前・タグ・ファイル・行）で書く。名前で絞れなければ、そう書いて代わりの絞り方を書く。
     - `selected` に、選ばれた件数の読み方と、0 件のときの出力（終了コードが 0 のままか）を書く。
     Fill every acceptance and stack key from the project's scripts: the in-progress marker, a `run_one` the tool can actually do, and how zero selected looks.
   - `commit_language`（`config.yaml`）: 既存のコミットの件名の言語。
   - `commit_style`（`config.yaml`）: 既存の件名の多くが `<type>(<scope>): ` の形なら `conventional`、そうでなければ `history`。根拠に件名を 2〜3 件示す。
   - `lenses`（`config.yaml`）: 使える観点を**すべて**下書きに並べ、プロジェクトを読んで、観点ごとに「入れる案／入れない案」と根拠（見つけたファイル）を書く。
     | 観点 | 入れる案にする目安 |
     |---|---|
     | `structure` | 常に（カタログがあるか、汎用のカタログを置いたとき） |
     | `security` | 外から呼ばれる口がある（HTTP のルート・CLI の入力・Webhook・メッセージの受け口） |
     | `concurrency` | 非同期の処理、DB への書き込み、ジョブ・定期実行、プロセス内のキャッシュがある |
     | `isolation` | テナント（組織・利用者ごとのデータ）がある、またはテストが DB・ファイル・環境変数を共有している |
     | `acceptance` | `tdd.acceptance` が `none` でない（外側のシナリオを閉じるたびに新しい文脈を 1 つ起動する） |
     観点を足すほど `review` の費用が増えることを、下書きに 1 行で書く。目安に当たらない観点も「入れない案」として理由つきで並べる（黙って落とさない）。
     List every lens in the draft with a proposed on/off and the evidence; note that each lens adds review cost.
   Fill values from the project itself; leave unknowns empty and say so — never invent a catalog, a command, or a known failure.
4. **下書きを見せて、ユーザーの了承を得てから書く。** / Show the draft; write only after the user agrees.
5. **個人用か共有かを聞く。**
   - 個人用: `.git/info/exclude` に `/.agent-discipline/` を足す方法を**案内するだけ**（自分では足さない）。
   - チームで共有: コミットしてよいと伝える（コミットはしない）。
   Ask personal or shared; only explain how to exclude or commit — do neither.
6. 書いたファイルと、空のままの項目を報告する。 / Report what was written and what is still empty.
