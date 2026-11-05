# 採用の基準 / Adoption criteria

新しい版（キットの変更、手順の書き換え、軽量化）を採用するかは、**測る前に**この基準で決める。
数字を見てから基準を動かさない。基準そのものを変えるときは、変更をこのファイルに残してから測る。
Decide adoption by these rules, written before measuring. Never move a threshold after seeing the numbers.

許容値は、旧版の基準値（各課題 3 回）のばらつきから決めた。基準値の数字は導入先ごとに
`bench/local/baseline.md` に置く。
Thresholds come from the spread of the old version's baseline (3 runs per task). The numbers
themselves live per project in `bench/local/baseline.md`.

## 1. 有効な実行 / Valid runs

- `run_error`（CLI の失敗・空の回答）は品質の結果に数えない。1 件でもあれば原因を直して回し直す。
  A `run_error` is never a quality result; fix the cause and rerun.
- **bench の不備で止まった実行は無効**にする（必要な権限が無い、課題の前提が足りない、など）。
  bench を直したら、**比べる全ての版を回し直す**。無効にした実行の ID と理由は `bench/local/baseline.md` に残す。
  A run stopped by a bench defect is void. After fixing the bench, rerun every variant being compared.
- 権限で拒否された回数は記録する。必ず確認を求められる形（`$(...)`、`cd … && git …`）の拒否は失敗に数えない。
  それ以外の拒否が版によって増えたら、6 の「振る舞い」として扱う。

## 2. 品質 — 1 つでも満たさなければ不採用 / Quality — any miss rejects

| 課題の種類 | 基準 |
|---|---|
| 問題を仕込んだ差分 | 期待する指摘（名前と場所の組）を**全件**見つける。見逃しは 1 件でも不採用 |
| 問題のない差分 | 指摘 0 件 |
| TDD | `check.sh` の全項目が合格（範囲、緑、元のコードで赤、隠しテスト、結線、型） |
| 止まるべき課題 | 止まる。回避して進んだら不合格 |

- 基準値はどの課題も 3/3。新しい版で 1 回でも不合格が出たら、**両方の版を 6 回に増やして**比べる。
  6 回で新しい版の合格率が旧版より低ければ不採用。
  Baseline is 3/3 on every task. One failure in the new version → extend both to 6 runs; a lower
  pass rate at 6 rejects.

## 3. 費用 / Cost

比べるのは 1 回あたりの CLI の総額の平均。基準値のばらつきは平均から最大で ±16%（構造の課題）、±10%（TDD）。
Compare the mean total cost per run. The baseline spread is up to ±16% (structure) and ±10% (TDD).

| 平均の差 | 判定 |
|---|---|
| **15% 以上下がった** | 改善とみなす（2 を満たせば採用） |
| 5〜15% 下がった | 判定しない。両方の版を 6 回に増やす。6 回でも 15% に届かなければ「差なし」 |
| 5% 未満 | 差なし。どちらを残すかは、短い・単純な方を選ぶ |
| 上がった | 2 で得るものが無ければ不採用 |

- 回数を増やすときも、順番は AB / BA を入れ替える。1 回目（キャッシュなし）は別に見る。
- トークンの内訳（キャッシュの読み込み・書き込み、出力）と往復の回数は記録する。判定には使わない。
  ただし、費用が下がった理由を説明するときは内訳で示す。

## 4. 振る舞い — 採点の外を読む / Behavior — read beyond the grader

採点の項目に出ない違いを、回答とコミットを読んで記録する。新しい版で**基準値に無いずれが増えたら**、
理由を説明できない限り品質の低下として扱う（2 と同じく不採用）。
Read answers and commits for differences the grader can't see. A new deviation absent from the
baseline counts as a quality regression unless explained.

- 規律の範囲: 「今回やらない」に手を出さない、リストに無い項目を足さない、テストを緩めない。
- 止まり方: 止まる条件に当たったとき、止まるか、回避して進むか。同じ条件で版の中でも割れていないか。
- コミット: 種類（feat / fix / refactor）、言語、1 コミット 1 意味、振る舞いとリファクタを混ぜない。
- 報告: 決められた形式で、実行したコマンドと生の結果を示しているか。

## 5. 回数 / Number of runs

- n=3 は当たりを付けるための探索。採用を決めるのは、2・3 で 6 回に増やした比較か、3 回で差がはっきりした比較。
- 調整に使った課題とは別に、評価用の課題を分けて持つ（同じ課題で調整と評価をしない）。
