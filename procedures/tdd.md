# tdd — TDD の共通の規律 / Shared TDD discipline

TDD の入口（`ad-cycle`、`ad-red`、`ad-green`、`ad-refactor`、`ad-commit`）が、`discipline.md` のあとに読む。
各段階の手順は `red.md`・`green.md`・`refactor.md`・`commit.md`、通しの流れは `cycle.md` にある。
Every TDD entry reads this after `discipline.md`. Stage procedures live in their own files.

今の版が扱うのは**単層**（内側のループだけ。不具合の修正、画面の流れを変えない小さな変更、単体の粒度の変更）。
受け入れテストを外側に置く二重ループは、まだ扱わない。リストが二重ループの形なら、そう伝えて止まる。
This version runs the single-layer loop only. If the list is a double-loop list, say so and stop.

## 絶対の規則 / Hard rules

1. **呼ばれた段階だけを行う。** 次の段階を「ついでに」やらない（`ad-cycle` は段階の境界だけを越える。中身の規律は緩めない）。
   Do only the stage you were called for. `ad-cycle` crosses stage boundaries, nothing else.
2. **テストを消さない・飛ばさない・期待値を緩めない。** 落ちているテストは情報である。例外は、リストの `[change]`・`[remove]` の項目だけ
   （承認された仕様の変更を出典に、red で既存のテストを書き換える・消す）。
   Never delete, skip, or weaken a test. Only `[change]` / `[remove]` items, backed by an approved spec change, may, in RED.
3. **その段階に要るファイルだけを触る。** / Touch only what the stage needs.
4. **段階の最後に、実際にテストを走らせて、生の結果を報告する。** 「通るはず」で終えない。走らせる範囲は下の「どこまで走らせるか」。
   End every stage with a real test run and its actual output.
5. **期待値を発明しない。** アサーションの値は、(1) 置き換え元・参照の実装の実際の振る舞いと既存のテスト、(2) 仕様・スキーマ・文書、
   (3) ユーザーの明示の指示（承認されたリストを含む）の順に取り、どこから取ったかを報告に書く。どれからも取れなければ、聞いて止まる。
   Every expected value has a source, in that order; name it. If none gives the value, ask and stop.
6. **迷ったら止まる。** 回しきることは目的ではない。 / When in doubt, stop.

## プロジェクトの情報 / Project facts

プロジェクト固有のことは、`profile.md` の `tdd` から読む。ここに書いていないことを推測で補わない。
Project-specific facts come from the profile's `tdd` block; never guess what it doesn't say.

| 項目 | 中身 |
|---|---|
| `tdd.suites` | スイートごとに `name`、全体を走らせるコマンド `all`、1 本に絞るコマンド `one`（`<path>` と `<name>` を置き換える）、`speed`（`fast` / `slow`） |
| `tdd.checks` | テストとは別に、緑の確認で走らせるもの（型の確認など）。無ければ `none` |
| `tdd.tests` | テストの置き場所と、倣うお手本のファイル（種類ごと） |
| `tdd.known_failures` | 最初から落ちていて構わないテスト（スイート・テストの名前・条件）。**ここに名前のあるものだけ**を除く。無ければ `none` |
| `tdd.hooks` | コミットのフックがすること（lint・整形・整形したファイルのステージのし直しなど）。無ければ `none` |
| `tdd.rules` | 着手の前に一度だけ読む、プロジェクトの規約。自動で読み込まれるものは書かない |

## テストのリスト / The test list

- **置き場:** `<根元>/.agent-discipline/lists/<ブランチ>.md`（ブランチ名の `/` は `-` にする）。worktree では、その worktree の根元。
  ツールの設定ディレクトリやプラグインの置き場には書かない。
  Lives at `<root>/.agent-discipline/lists/<branch>.md`; never under a tool's config folder.
- **ブランチを持たない（detached）ときや、そのブランチのリストが無いときは、止まって伝える。** 別のブランチのリストを使わない。
- **リストを書けないとき**（権限が無い、書き込みが失敗した）は、**止まって報告する。** 状態を残せないまま進めない。
  If the list cannot be written, stop and report — never carry on without the state.
- **コミットに入れない。** ステージするのは、作業で触ったファイルを名指しで。
- **形式:**
  ```
  # <対象>
  モード / Mode: 単層
  出典 / Source: <期待値の出典>
  完了条件 / Done when: <振る舞いに [ ] が無い、どのスイートが緑か>

  ## 振る舞い / Behaviors
  - [ ] [<印>] <どこで>: <振る舞いを 1 文> — 出典: <どこから取るか>

  ## 今回やらない / Out of scope
  - <項目> — 理由: <なぜ>
  ```
- **印:** `[ ]` 未着手、`[~]` 着手中（red が付ける）、`[x]` 緑（green が付ける）。種類は ZOMBIES の頭文字（`[O/B]` など）か、
  既存のテストを書き換える `[change]`、廃止する振る舞いのテストを消す `[remove]`。
- **項目を勝手に足さない。** 新しく要る振る舞いに気づいたら、報告して、足すかどうかはユーザーが決める。
  Never add items yourself; report and let the user decide.

## どこまで走らせるか / How much to run

| 段階 | 範囲 |
|---|---|
| red | 書いたテスト 1 本だけ（`one`） |
| green | ① そのテスト → ② `fast` のスイートは全体（`all`）と `tdd.checks` → ③ `slow` のスイートは触ったパスだけ |
| refactor | 1 手ごとに、その手が触った範囲。段階の最後に green の②③ |
| commit | `slow` のスイートも全体 |

- 同じ作業ツリーで、直前の段階が同じ範囲を走らせて結果がまだ有効なら、走らせ直さない（省いたことと、どの結果を使ったかを書く）。
- lint と整形は、`tdd.hooks` がするならフックに任せる。
- `tdd.known_failures` に名前のある失敗だけを除く。それ以外の、作業と関係のないテストが落ちたら止まる。

## 報告 / Report

段階の最後をこの形で締める（当てはまらない行は省く）。報告は `profile.md` の `language` で書く。
```
変更: <触ったファイルと一言>
テスト: <走らせたコマンド> → <生の出力の要点>
出典: <期待値をどこから取ったか>
残り: <未着手 n 件。0 なら「完了」>
次:   <次の段階>
```
