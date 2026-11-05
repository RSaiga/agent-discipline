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
   - `lenses.structure.catalog`: プロジェクトのリファクタリングの規約やカタログ。見つからなければ空のままにし、そのことを報告で伝える（推測で作らない）。
   - `lenses.structure.catalog_auto_loaded`: その規約が、フォルダを対象にして自動で読み込まれる設定になっているなら `true`。分からなければ `false`。
   - `tdd.suites`: プロジェクトが実際に使っているテストのコマンド（README、タスクランナー、パッケージの scripts など）。全体と 1 本に絞る形を、試さずに書けるものだけ書く。
     `speed` は分からなければ書かず、そのことを伝える（最初に `ad-cycle` を回すときに測る）。
   - `tdd.tests`: 既存のテストの置き場所と、倣うお手本にできるテストのファイル。
   - `tdd.checks`・`tdd.known_failures`・`tdd.hooks`・`tdd.rules`: プロジェクトから読み取れたものだけ。無ければ `none`。既知の失敗は推測で書かない。
   - `commit_language`（`config.yaml`）: 既存のコミットの件名の言語。
   Fill values from the project itself; leave unknowns empty and say so — never invent a catalog, a command, or a known failure.
4. **下書きを見せて、ユーザーの了承を得てから書く。** / Show the draft; write only after the user agrees.
5. **個人用か共有かを聞く。**
   - 個人用: `.git/info/exclude` に `/.agent-discipline/` を足す方法を**案内するだけ**（自分では足さない）。
   - チームで共有: コミットしてよいと伝える（コミットはしない）。
   Ask personal or shared; only explain how to exclude or commit — do neither.
6. 書いたファイルと、空のままの項目を報告する。 / Report what was written and what is still empty.
