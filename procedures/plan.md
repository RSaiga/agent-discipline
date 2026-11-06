# plan — テストのリストを作る / Plan the test list

テストも実装も書かない。書いてよいのは、そのブランチのリスト（`tdd.md`「テストのリスト」の置き場）だけで、**承認を得てから**書く。
`profile.md`・`config.yaml` は書かない。コミットしない。
Write no code and no tests. The only file you may write is this branch's test list, and only after approval.

## 1. 書く前に確かめる / Before anything

- **すでにリストがあれば、** 中身と進み具合（`[x]`・`[~]` の数）を示し、置き換える・足す・やめるのどれにするかを聞いて止まる。
  依頼に「承認済み」とあっても、それは新しい下書きの承認であって、今あるリストを置き換える承認ではない。`[x]`・`[~]` の項目を黙って消さない。
  If a list exists, show it with its progress and ask whether to replace, extend, or stop. Approval of a new draft is not approval to replace it.
- 対象が依頼に書かれていなければ、作業中の差分とブランチ名から推定して示し、確かめる。

## 2. 材料を集める / Gather

- `tdd.rules` の規約を読む。期待値の出典（依頼、仕様、置き換え元の実装、既存のテストの期待値）を特定する。
- **既存の仕組みを先に探す。** 同じことをしている関数・型・画面を検索し、作り直さずに使えるものを挙げる。
- `tdd.acceptance` があれば、受け入れテストの形式・置き場所・お手本を確かめる。

## 3. 作業の種類とモードを決める / Kind of work and mode

| 作業 | モード | 外側の始め方 |
|---|---|---|
| 新しい機能 | 二重ループ | 先頭のシナリオを `[skeleton]`（最初の通り道）にする |
| 既存の機能の変更 | 二重ループ | 最初の通り道を置かない（既存の経路がそれにあたる） |
| 不具合の修正、画面の流れを変えない小さな変更、1 つの境界だけの変更 | 単層 | 外側を持たない |

- 判断が割れるなら、聞く。 / If the choice is unclear, ask.
- `tdd.acceptance` が `none` なら、二重ループは選べない。そう伝え、単層で組めるかを示す。
- **既存の機能の変更なら、古い振る舞いを確かめている既存のテストを洗い出す。** 変わる値・文言・条件でテストを検索し、
  変わるものを `[change]`、廃止するものを `[remove]` の項目にする（受け入れテストも同じ）。変わらない振る舞いのテストは入れない。
  漏れると、green で既存のテストが落ちて止まる。
  For a change, search for every test pinning the old behavior and list it as `[change]` / `[remove]`; leave unchanged behavior alone.

## 4. 考えて、並べる / Think, then order

急いでリストを出さない。このフェーズの価値は分け方にある。 / Don't rush the list; the value of this stage is the decomposition.

- **外側（二重ループのとき）:** 受け入れ条件を、外から見える具体例にする。1 シナリオ = 1 つの受け入れ例。主要な行動だけを載せ、
  境界と例外の細かい変種は内側に回す。並べ順は Zero → One → Many。
- **内側:** シナリオごと（単層ならリスト全体）に、ZOMBIES で洗い出す。
  - Z → O → M の順に一般化し、Boundary と Exceptional は意味を持つ段に挟む（末尾にまとめない）。Interface（引数と応答の形）は Zero の項目で決める。
  - 1 項目 = 1 つの振る舞い。各項目に、どの境界のテストか（`tdd.tests` の種類）を書く。層ごとに項目を割らない。
  - 1 件目が固定値で通り、次の項目がそれを一般化させるように並べる。
  - 不具合の修正なら、不具合を再現して落ちるテストを先頭に置く。
- **実際に使われる経路に絞る。** 呼ばれていない分岐やパラメータは「今回やらない」に理由つきで置く。
- **出典の無い項目を置かない。**

## 5. 下書きを見せる / Present the draft

見せるもの: モードとその理由、洗い出した既存のテスト（それぞれ `[change]`・`[remove]`・影響なしと理由。6 の「既存のテスト」の節にそのまま残す）、シナリオ（二重ループのとき）、
内側の各項目（振る舞い 1 文・境界・出典）、今回やらないことと理由、完了の条件、ZOMBIES の網羅（Z/O/M/B/E ごとに、対応する項目か「該当なし」と理由）。

**承認を待つ。** 承認がなければ、書かずに止まる。承認の範囲は見せた下書きそのもので、見せていない変更を足さない。
依頼の中で、確認を待たずに書くよう明示されていれば、それを承認とみなす（`discipline.md` の優先順位の 1）。
Wait for approval; without it, stop without writing. An explicit instruction in the request to write without waiting counts as approval.

## 6. 承認のあとで書く / After approval

`tdd.md` の形式で書く。**洗い出した既存のテストは、リストにも残す**（下書きで見せただけでは、次の段階から見えない）。
`## 今回やらない` の前に、次の節を置く。既存の振る舞いに触れない作業でも、何を検索して見つからなかったかを書く:
```
## 既存のテスト / Existing tests
- [change] <path>:<line> 「<テスト名>」 — <どう変わるか>
- [remove] <path>:<line> 「<テスト名>」 — <どの振る舞いを廃止するか>
- 影響なし <path>:<line> 「<テスト名>」 — <なぜ変わらないか>
- 見つからなかった — 検索した語: <…>
```
`[change]`・`[remove]` の行は、振る舞いの項目としても置く（red で書き換える・消す）。
Keep the existing-test inventory in the list itself, with a reason for every "unaffected" entry.

二重ループのときは、`## 振る舞い` の代わりに次の節を置く:
```
## 受け入れシナリオ / Acceptance
### [ ] A1 [skeleton] <シナリオ名> — <受け入れテストのファイル> — 出典: <…>
    Given … / When … / Then …
### [ ] A2 <シナリオ名> — <ファイル> — 出典: <…>
  - [ ] [O/E] <境界>: <振る舞いを 1 文> — 出典: <…>
```
書けなければ（権限、書き込みの失敗）、止まって報告する。

## 7. 止まる / Stop

「モード / シナリオ n 本 / 内側 m 件 / 今回やらない k 件」と完了の条件、リストの置き場を報告する。
次は、単層なら `ad-cycle` か `ad-red`、二重ループなら `ad-accept`（通しの `ad-cycle` は、今の版では単層だけ）。

**しないこと / Never:** テストや実装を書くこと、実装の方針を決め込むこと（設計は green と refactor で決まる）、境界や例外の変種を外側に積むこと、
使われていない経路をリストに入れること、出典の無い項目、承認の前に書くこと、今あるリストを聞かずに置き換えること。
