# second-opinion — 別の AI にも読ませる / A second opinion from another AI

`review` と `tdd-plan` だけが使う。呼び出しに `--second` があるときだけ動く。ほかの入口では使わない。
Used only by `review` and `tdd-plan`, and only when the invocation contains `--second`.

## 1. 2 人目を選ぶ / Pick the second

- `config.yaml` の `second_opinion_commands`（引数の配列の一覧）を上から見て、**自分を動かしているツールと同じプログラム**（配列の最初の要素）を飛ばし、
  最初に残ったものを 2 人目にする。
- 一覧が無ければ「2 人目が設定されていない」、すべて自分と同じなら「別の AI の候補が無い」と伝え、1 人目だけで進める（止まらない）。
- 2 人目に何を使ったか（配列の最初の要素）を報告に書く。
Skip candidates whose program is the tool running you; use the first one left. None configured or none left → say so and continue alone.

## 2. 2 人目を動かす / Run it

- 渡すもの（下の 3・4）をプロンプトにして、**標準入力**で渡す。渡し方は、引用した区切りのヒアドキュメント（`<<'AD_SECOND_EOF'`。展開されない）
  を先に使う。一時ファイルは、リポジトリの外に書けるときだけ使う（書けない実行環境が多い）。
  出力は、ツールが裏の実行の出力を受け取れるならそれで受け、ファイルに書かない。
  置き換えるのは `{root}`（プロジェクトの根元）だけ。引数は配列の順に並べ、空白や記号を含む要素だけを引用する（すべてを引用すると、
  「プログラム名で始まる」形の許可の規則に合わなくなる）。シェルの文字列に組み立て直さない。プロンプトを引数に入れない。
  ヒアドキュメントの本文に、シェルが検査で止める書き方（JSON の例など）が混ざって止められたら、その部分を文章に書き換えて渡し直す。
- 2 人目は読むだけ。書くことを頼まない。
- 実行環境の制限（サンドボックスなど）で起動できないなら、そのツールのふつうのやり方で許可を求める。制限を緩める設定を足さない。
  許可されなければ、止まったとして扱う。
- 10 分で終わらない・0 以外で終わる・決めた形で返さないときは、2 人目は止まったとして扱う。1 人目の結果はそのまま使う。
The prompt goes on stdin, by a quoted heredoc first (a temp file outside the repo only when writable); only `{root}` is substituted. If a sandbox blocks it, ask for permission the tool's usual way;
never loosen it. A timeout (10 min), a non-zero exit or a malformed answer means the second stopped; the first's result stands.

## 3. review で / In review

**1 人目の結論を渡さない。** 渡すのは、`review.md`「観点を実行する」の `subagent` と同じもの（観点のファイル・基準のファイル・見本のファイル・
プロジェクトの根元・`diff_base`・対象のファイルの一覧）と、対象の取り方（範囲、プルリクエストなら `<先頭>`）だけ。
すべての観点を 1 回で読ませ、返事は観点ごとに `### 観点: <名前>` の節に分け、節ごとに観点のファイルの形の指摘と最後の行を書かせる。

**同時に動かす。** 2 人目を先に裏で起動し、そのあいだに 1 人目が観点を読み、終わってから 2 人目を待つ。裏で起動できなければ、1 人目のあとに動かす。
観点が読んでいるあいだ、誰も書かない。作業ツリーの指紋は、2 人目が終わってからとる。
Never pass the first's findings. Start the second in the background first, run the lenses, then wait. If backgrounding is not possible, run it after.

**突き合わせる。** 指摘を、観点・項目の番号・場所（同じファイルの近い行か、同じ関数）で組にする。

| 組の結果 | 書き方 |
|---|---|
| 両方が指摘した | 1 つの指摘にまとめ、見出しの後ろに `［両方］`。確信度が違えば両方の確信度とそれぞれの理由を並べ、`［両方・確信度が違う］` |
| 1 人目だけ | `［1 人目だけ］` |
| 2 人目だけ | 指摘の場所のコードを読み、確かめられたら `［2 人目だけ・確かめられた］`。確かめられなければ `［2 人目だけ・確かめられない: <理由とコードの場所>］` |

- **どの指摘も消さない。** 突き合わせる側は 1 人目なので、自分の側に寄せない。2 人目だけの指摘を「確かめられない」とするときは、そう判断したコードの場所を書く。
- 指摘の見出しの形（観点のファイルの「指摘の形」）は崩さない。印は見出しの後ろに足す。
- 要約の前に 1 行: `突き合わせ: 両方 <n> / 1 人目だけ <n> / 2 人目だけ <n>（確かめられた <n>）/ 確信度の違い <n>`。
Pair findings by lens, item and location; tag each as both / first only / second only (verified or not, with the code location). Never drop one.

**最後の行。** 組にしたものは 1 件と数える。`［2 人目だけ・確かめられない］` は `UNVERIFIED` として数え、それ以外の指摘は `FINDINGS` として数える。
優先順位は `review.md`「まとめる」と同じ。2 人目が止まったときは、最後の行の前に `セカンドオピニオン: 止まった（<理由>）` と書き、最後の行は 1 人目だけで決める。
An unverified second-only finding counts as UNVERIFIED. If the second stopped, say so on the line before the last line, which then reflects the first alone.

## 4. tdd-plan で / In tdd-plan

**下書きができてから動かす**（同時には動かさない）。渡すのは、依頼・集めた材料（ファイルのパス）・見せる予定の下書き。
2 人目には、良し悪しの感想ではなく**抜けと誤り**を、次の点に照らして探させる:

- 外から観察できない・価値の無いシナリオや項目が混ざっていないか
- 抜けているシナリオや項目がないか（失敗のとき、境界、権限、空のとき）
- すでに成り立っている振る舞いを項目にしていないか
- 価値の順になっているか。どこで止めても無駄が少ないか
- ストーリーに分けるべき大きさではないか

返事は `- [P<番号>] <指摘> — <根拠（依頼・材料・下書きの場所）>` の行で書かせ、最後の行を `## PLAN REVIEW <件数>` にさせる。

1 人目は、指摘ごとに `採用`（下書きをどう直したか）か `不採用`（理由）を付ける。直した下書きと、指摘と返答の表を合わせて見せ、
いつもどおり承認を待つ（`plan.md`「下書きを見せる」）。2 人目が止まったときは、そう書いて、1 人目の下書きだけを見せる。
Run after the draft exists. The second looks for gaps and errors against the list above; the first answers each point (adopted: how / rejected: why),
shows the revised draft with the table, and waits for approval as usual.
