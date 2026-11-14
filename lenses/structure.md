# structure — 構造の観点 / Structure lens

変更を、下の汎用の項目と、プロジェクトのリファクタリングのカタログ（`profile.md` の `lenses.structure.catalog`。無くてよい）に照らして読み、
構造の問題（code smell）を**名前つき**で指摘し、取るべき手当て（move）を示す。挙動の問題（バグ）はこの観点では扱わない。
Read the change against the generic items below and the project's refactoring catalog (optional), name each smell, and propose the move. Bugs are out of scope.

## 基準 / The rubric

- **判定の基準は、下の項目とプロジェクトのカタログだけ。** 記憶にある smell の一覧は使わない。カタログの定義と、そこが指す根拠（各 smell の置き場所）を使う。
  The rubric is the items below plus the project's catalog; never rely on a list kept in memory.
- **カタログを先に疑う。** 順番はカタログの並び順（優先度が書いてあればその順）。そのあとで、下の項目のうちカタログに無いものを疑う。
  Suspect the catalog first, in its order; then the items below that the catalog lacks.
- **カタログが勝つ。** 同じ名前の smell がカタログにあれば、カタログの定義を使う。名前が違っても同じ匂いを指していれば、カタログの名前で指摘する。
  The catalog wins: same name → its definition; same smell under another name → its name.

## 項目 / Items

カタログが無くても、カタログに載っていなくても、この 6 つは疑う。 / Always suspect these six, catalog or not.

| smell | 疑うところ | 直し方 |
|---|---|---|
| Duplicated Code | 同じ規則や計算が 2 か所にある | 1 つの関数か型に置き、両方からそれを呼ぶ |
| Feature Envy | ほかのモジュールのデータばかり読む関数 | その処理をデータのそばへ移す |
| Long Function | いくつものことを順にしている関数 | 段ごとに名前を付けて切り出す |
| Mysterious Name | 何のためのものかを語らない名前 | 目的に合わせて名前を変える |
| Data Clumps | いつも一緒に渡される値の組 | 1 つの型にまとめる |
| Primitive Obsession | 意味と規則を持つ値が、素の文字列や数値のまま扱われている | 規則を持つ小さな型にする |

## 読み方 / How to read

- **変更そのものは差分から読む。** / Read the change itself from the diff.
- **周りを確かめるときは、ファイルを開かずに、前後の行を付けた検索で必要な行だけを見る**（`grep -n -C 3` の類い）。
  ファイルを開くと、そのフォルダを対象にしたプロジェクトの規約がまとめて読み込まれることがある。ファイル全体が要るときだけ開く。
  Check surroundings with a context search, not by opening files — opening one can pull in folder-scoped rules. Open a whole file only when needed.
- **確かめたいことを先に洗い出し、検索は 1 回の往復でまとめて出す。** 差分を読み終えたら、疑っている smell ごとに「どこを見れば決められるか」を挙げ、
  その検索をすべて同じ往復で行う。結果を見て追加で確かめるのは、多くても 1 往復まで。
  List what you need to confirm, then send all those searches in one turn; allow at most one follow-up turn.
- **確かめずに判断しない。** 「別の場所が同じ規則を持っている」「型がすでに持っている」と指摘するなら、その場所を検索で実際に見てから書く。
  Before claiming another place already holds the rule, look at it.

## 判定の心得 / How to judge

- **具体的な手当てが言えない指摘はしない。** 一般論ではなく、**その行がなぜその smell か**を 1〜2 行で示す。
  No finding without a concrete move; say why this line is that smell.
- **「移しただけ」を疑う。** 処理を関数やファイルに移しても、別の型の中身を読み続けているなら、責務は動いていない（Feature Envy が残っている）。
  Suspect "moved, not re-homed": extracted code that still reads another type's internals.
- **同じ知識が 2 か所にないか。** 「〜層でも防御」のようなコメントは、重複の目印になりやすい。
  Look for the same rule in two places; defensive "also checked here" comments often mark it.
- **確信度を付ける**（高 / 中 / 低）。低いものは「観点」として軽く出す。
- **誤検出を出さない。** 指摘の数より、指摘の正しさを優先する。
  Prefer precision over count.

## 指摘の形 / Finding format

指摘ごとに、この形で書く（優先度の高い順）:

```
### [<smell 名>] — <file>:<line>  (確信度: 高/中/低)
- 何が問題か: <その行がなぜその smell か。1〜2 行>
- 提案する move: <具体的な手当て>
- 根拠: <カタログのファイル、または lenses/structure.md> → "<smell 名>"
```

`<smell 名>` は、カタログの見出しか上の項目の名前をそのまま使う。 / Use the catalog's or the items' own smell names.
