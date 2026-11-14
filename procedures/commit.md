# commit — 緑から、意味の単位でコミットする / Commit one meaning at a time, from green

実装もテストも直さない。 / Change neither code nor tests here.

1. **コミットしてよいかを決める**（`config.yaml` の `commit`）。
   - `never`: コミットせず、コミットの案（ステージするファイルとメッセージ）を示して止まる。
   - `on-request`: `tdd-commit` か `tdd-cycle` を明示的に呼んだことを、依頼とみなす。
   - `on-green`: 緑になった区切りごとにコミットする。
2. **緑を確かめる。** `slow` のスイートも全体を走らせる（`tdd.md`「どこまで走らせるか」）。赤ならコミットせず、何が落ちているかを報告して止まる。
3. **差分を全部読む。** 作業で自分が触っていないファイルが混ざっていたら、ステージしない。切り分けられなければ止まる。
4. **触ったファイルを名指しでステージする。** すべてをまとめてステージしない。リスト（`.codence/`）は入れない。
5. **振る舞いの変更とリファクタを同じコミットに入れない。** 両方あれば、振る舞い → リファクタの順に分ける。種類が 2 つ浮かんだら、コミットも 2 つ。
6. **メッセージ:** 形は `config.yaml` の `commit_style`（既定は `conventional`）、件名の言語は `commit_language` で決める。
   - `conventional`: Conventional Commits（https://www.conventionalcommits.org/）の 1 行（`<type>(<scope>): <件名>`）。本文と破壊的変更の印は使わない。
   - `history`: `git log -20 --format=%s` を読み、既存の件名の形（接頭辞やタグ、大文字と小文字、動詞の形、長さ）に合わせた 1 行。
     下の type の区別はそのまま使い、履歴に種類の書き方があればそれで表す。無ければ件名の言葉で分かるようにする（リファクタだと読めるように）。
     With `history`, match the form of the last 20 subjects; keep the type distinction below, expressed the way the history does.
   - type: `feat` 新しい振る舞い / `fix` 不具合の修正 / `refactor` 振る舞いを変えない構造の変更 / `test` テストだけ / `chore` 依存・設定など。
     テストの期待値を書き換えた・テストを足したコミット（`[change]` を含む）は `refactor` にしない。`refactor` は期待値に触れていないコミットだけ。
     A commit that changed or added an expectation (including `[change]`) is never `refactor`.
   - 何を成したかは、前のコミットのあとに `[x]` になった項目から読む。製品にとって何が変わるかを書き、開発の経緯（「テストを緑にした」など）は書かない。
7. **フックを迂回しない。** 落ちたら原因を報告して止まる。`tdd.hooks` が整形したファイルをステージし直すなら、コミットのあとに意図しない差分が残っていないか確かめる。
8. **push しない。**
9. **止まる。** コミットのハッシュと件名を報告する。

**しないこと / Never:** 赤のままのコミット、すべてをまとめたステージ、フックの迂回、push、振る舞いとリファクタの混在、コミットを通すための実装やテストの修正。
