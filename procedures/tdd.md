# tdd — TDD の共通の規律 / Shared TDD discipline

TDD の入口（`tdd-plan`、`tdd-cycle`、`tdd-accept`、`tdd-red`、`tdd-green`、`tdd-refactor`、`tdd-commit`）が、`discipline.md` のあとに読む。
リストを作るのは `plan.md`、外側の段階は `accept.md`、内側の段階は `red.md`・`green.md`・`refactor.md`・`commit.md`、通しの流れは `cycle.md` にある。
Every TDD entry reads this after `discipline.md`. Stage procedures live in their own files.

単層と二重ループ（受け入れテストを外側に置く）の両方を扱う。段階ごとの入口でも、通しの `tdd-cycle` でも回せる。
Handles both the single layer and the double loop, stage by stage or end to end with `tdd-cycle`.

**二重ループ:** 外側は受け入れシナリオ 1 本、内側はそれを緑にするための項目。シナリオごとに、外側を書いて振る舞いで落とす（accept）→
内側を red → green → refactor で 1 件ずつ → 内側が尽きたら外側を走らせる（accept）。外側の失敗が、次に足りない振る舞いを 1 つ示す。
新しい機能の最初のシナリオは**最初の通り道**（`[skeleton]`）: 外側の 1 本だけで、全部の層を最も薄くつなぐ。内側のテストは書かない。

## 絶対の規則 / Hard rules

1. **呼ばれた段階だけを行う。** 次の段階を「ついでに」やらない（`tdd-cycle` は段階の境界だけを越える。中身の規律は緩めない）。
   Do only the stage you were called for. `tdd-cycle` crosses stage boundaries, nothing else.
2. **テストを消さない・飛ばさない・期待値を緩めない。** 落ちているテストは情報である。例外は、リストの `[change]`・`[remove]` の項目だけ
   （承認された仕様の変更を出典に、red で既存のテストを書き換える・消す）。
   Never delete, skip, or weaken a test. Only `[change]` / `[remove]` items, backed by an approved spec change, may, in RED.
   ほかの例外は、外側が緑になった直後の**外側の棚卸し**と、type 2 での**未コミットの新しいテスト 1 本の取り消し**（どちらも `refactor.md`）。
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
| `tdd.suites` | スイートごとに `name`、全体を走らせるコマンド `all`、1 本に絞るコマンド `one`（`<path>` と `<name>` を置き換える）、`speed`（`fast` / `slow`。無ければ `tdd-cycle` が最初の全体の実行で決め、単独の段では `slow` として扱う） |
| `tdd.checks` | テストとは別に、緑の確認で走らせるもの（型の確認など）。無ければ `none` |
| `tdd.tests` | テストの置き場所と、倣うお手本のファイル（種類ごと） |
| `tdd.known_failures` | 最初から落ちていて構わないテスト（スイート・テストの名前・条件）。**ここに名前のあるものだけ**を除く。無ければ `none` |
| `tdd.hooks` | コミットのフックがすること（lint・整形・整形したファイルのステージのし直しなど）。無ければ `none` |
| `tdd.rules` | 着手の前に一度だけ読む、プロジェクトの規約。自動で読み込まれるものは書かない |
| `tdd.acceptance` | 受け入れテストの `format`・`path`・`example`、進行中のタグを含めて 1 本だけ走らせる `run_one`（`<name>` を置き換える）、タグを外したあとの既定の実行 `run_default`、選ばれた件数の読み方 `selected`。持たないプロジェクトは `none` |
| `tdd.stack` | 受け入れテストが要るスタックの `up`（準備ができたかの確かめ方と待つ上限を含む）・`status`・`down`・`restart_when`（どの変更で何を再起動するか）・`migrate`・`reset`（テスト用のデータを空にする方法と確かめ方）・`owner`（自分が起動したものの見分け方）・`failure_artifacts`（失敗の記録の場所）。スタックが要らなければ `none` |

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
- **二重ループのリスト**は `## 受け入れシナリオ` の下にシナリオ（`### [ ] A<n> <名前>`）を並べ、その下に内側の項目を置く（形式は `plan.md`）。
  シナリオの印: `[ ]` 未着手、`[~]` 進行中のタグを付けて書き、振る舞いで落ちるのを見た、`[x]` 緑になってタグを外した。**進行中の `[~]` のシナリオは常に 1 本だけ。**
  内側の項目は、進行中のシナリオの下から取る。
- **項目を勝手に足さない。** 新しく要る振る舞いに気づいたら、報告して、足すかどうかはユーザーが決める。例外は 1 つだけ:
  承認されたシナリオの外側の失敗が示す、足りない振る舞いを 1 件、そのシナリオの内側に足す（`accept.md`。出典は「シナリオ A<n> の失敗」）。
  Never add items yourself — except the one inner item `accept.md` derives from an approved scenario's outer failure.

## どこまで走らせるか / How much to run

| 段階 | 範囲 |
|---|---|
| accept | 外側のシナリオ 1 本だけ（`run_one`）。閉じるときは、タグを外してから既定の実行（`run_default`） |
| red | 書いたテスト 1 本だけ（`one`） |
| green | ① そのテスト → ② `fast` のスイートは全体（`all`）と `tdd.checks` → ③ `slow` のスイートは触ったパスだけ |
| refactor | 1 手ごとに、その手が触った範囲。段階の最後に green の②③ |
| commit | `slow` のスイートも全体 |

- 同じ作業ツリーで、直前の段階が同じ範囲を走らせて結果がまだ有効なら、走らせ直さない（省いたことと、どの結果を使ったかを書く）。
- lint と整形は、`tdd.hooks` がするならフックに任せる。
- `tdd.known_failures` に名前のある失敗だけを除く。それ以外の、作業と関係のないテストが落ちたら止まる。
- **選ばれた件数を必ず確かめる。** 成功で終わっても、選ばれたテストが 0 件なら、それは緑ではない。`selected` の読み方で件数を確かめ、
  0 件なら止まって報告する（走らせ方が対象を選べていない）。
  A run that selected nothing is not green, whatever its exit code.

## スタック / The stack

受け入れテストがスタックを要るときの約束。コマンドは `tdd.stack` から読む。
- **自分が起動したものだけを使い回し、止める。** 起動の前に `status` を見る。ポートを他のプロセスが使っていたら、**止めずに**報告して止まる。
  自分のものでないプロセスを止めない。
  Reuse and stop only what you started; if another process holds the port, report and stop — never stop it.
- **準備ができたかを確かめてから走らせる。** `up` が待つ上限のうちに準備ができなければ、報告して止まる。
- **変更のあとは `restart_when` のとおりに再起動し、`migrate` を当ててから**走らせる。古いコードに対して走らせた結果を使わない。
- **データの残りを疑う。** 外側の失敗が前の実行の残りに見えたら、`reset` で空にして走らせ直して切り分ける。
- **片付け:** リストが尽きたとき、止まるとき、中断するときは、自分が起動したスタックを `down` で止め、止めたことを報告する。
  段階の入口を 1 つだけ呼ばれたときは、次の段階で使えるよう動かしたままにしてよい（そのことを報告に書く）。

## 報告 / Report

段階の最後をこの形で締める（当てはまらない行は省く）。報告は `profile.md` の `language` で書く。
```
変更: <触ったファイルと一言>
テスト: <走らせたコマンド> → <生の出力の要点>
出典: <期待値をどこから取ったか>
残り: <未着手 n 件。0 なら「完了」>
次:   <次の段階>
```
