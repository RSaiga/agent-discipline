# refactor — 緑のまま構造だけを直す / Restructure while green

振る舞いを変えない。テストの期待値を変えない。 / No behavior change; assertions untouched.

呼び出しの指定で、3 つの型に分かれる。 / The invocation picks one of three kinds.

| 指定 | 型 | いつ使うか |
|---|---|---|
| なし | type 1 — 散らかりを片づける | green の直後に、直近の差分の匂いを取る |
| `type2` | type 2 — 変更を簡単にしてから、簡単な変更をする | green が「通すのに大きな構造の変更が要る」と止まったあと |
| `outer` | 外側の棚卸し | 外側のシナリオが緑になった直後 |

## 何のために整えるか / Why, how, what

- **WHY — 変更に備える。** Getting ready for change.
- **HOW — 匂いを取り除く。** 基準は `lenses/structure.md` の項目と `profile.md` の `lenses.structure.catalog`。 / Remove code smells.
- **WHAT — 設計が残る。** 設計の時間を別に取るのではなく、輪の中で少しずつ。リファクタは片づけであり、設計でもある。
  Design emerges a little at a time inside the loop; refactoring is tidying and design at once.

## 設計原則 / Design principles

直すときは、**どの原則に向けて直すのか**を言う（報告に、直したものごとに書く）。原則は 3 つの群で、**変化に強い設計**（Dynamic Design）が疎結合と高凝集を束ねる。
Say which principle each change moves toward.

- **疎結合 / Low coupling**
- **高凝集 / High cohesion**
- **モデリング / Modeling**

| 手 / Move | 原則 | どこから来るか |
|---|---|---|
| 重複をなくす (No duplicate) | 疎結合・高凝集 | HOW（匂いを取る） |
| 尋ねるな、命じよ (Tell, Don't Ask) | 高凝集 | HOW |
| 型で表す (Typing) | 高凝集・モデリング | HOW |
| 意図を示す — 命名 (Show your intent) | モデリング | HOW |
| そのまま対応づける (Direct Mapping) | モデリング | WHAT（設計） |
| 変化を守る (Protected Variation) | 疎結合 | type 2 |
| SOLID? — Perhaps not | 疎結合 | — |

- **Direct Mapping** — ドメインとコードを対応づける。ただし、ドメインモデルは着想のためのもので、そのまま置き換えるためのものではない。
  Domain model is for inspiration, not for transformation.
- **Protected Variation** — 継ぎ目は、変更が**実際に来た場所**に置く。予測した場所には置かない。
  Put the seam where the change actually arrives, not where you predict it.
- **SOLID? — Perhaps not** — 疎結合の本当の物差しは結合度と凝集度。SOLID はその一つの形にすぎず、開放閉鎖の原則は推測の拡張点を招きやすい。
  来るかもしれない変更のための抽象やインターフェースは作らない。 / The real measures are coupling and cohesion; no speculative extension points.

## type 1 — 散らかりを片づける / Tidy the mess green just left

1. **緑であることを確かめる。** 直前の green の結果がまだ有効なら、それを使う。緑でなければ止まる。
2. **直近の変更を読み、直す価値のある構造の問題を挙げる。** 基準は `lenses/structure.md` の項目と `profile.md` の `lenses.structure.catalog`
   （`lenses/structure.md` の判定の心得に従う。`config.yaml` の `lenses` に `structure` が無ければ使わない）と、`tdd.rules` の規約。
   プロジェクトの規約に反している箇所を先に直す。基準がどちらも無ければ、そう伝えて何もしない。
   テストのコードも対象（準備の重複をまとめる、名前を直す）。ただし、何をどの値で確かめるか（アサーション、期待値、本数）は変えない。
   **直すものが無ければ、無いと言って何もしない。** リファクタをひねり出さない。
   Name the structural problems from the catalog and the project's rules. Nothing to fix → say so and change nothing.
3. **バグを見つけたら直さない。** 報告し、落ちるテストを書く red からやり直すことを伝える。
4. **1 つずつ直し、そのたびにその手が触った範囲のテストを走らせる。**
5. **アサーションか期待値を変えないと緑にならないなら、それは設計の変更。** 止まって報告する。
6. **段階の最後に、green と同じ範囲で緑を確かめる。**
7. **止まる。** 報告し、次の段階を伝える（直したものがあればコミット、未着手が残っていれば red、無ければ完了）。

## type 2 — 変更を簡単にしてから、簡単な変更をする / Make the change easy, then make the easy change（`type2`）

green が「通すのに大きな構造の変更が要る」と止まったあとに使う。 / Use after green stopped because passing needs a big structural change.

1. **落ちている新しいテストを取り消す。** 取り消すのは、まだコミットしていない、green が通せなかったテスト 1 本の追加分だけ。ほかの変更には触らない。
   取り消したテストのファイル・名前・中身を報告に残す（red で書き直すため）。取り消す 1 本が特定できない（複数ある、コミット済み）なら止まる。
   Undo only the single uncommitted failing test green could not pass, keeping its file, name and body in the report.
2. **緑に戻ったことを確かめる。** 戻らなければ止まる。
3. **直すのは「取り消したテストを通しやすくする構造」だけ。** green が報告した「変更を難しくしているもの」から始める。
   継ぎ目は、そのテストが実際に求めている場所に置き、それより先回りしない（Protected Variation）。直し方は type 1 の 3〜6 と同じ。
   Restructure only as far as that test needs; put the seam where it asks, no further.
4. **リストの該当項目を `[~]` から `[ ]` に戻す。**
5. **止まる。** 報告し、構造の変更は `refactor` の 1 コミットにすること、次は red でその項目を書き直すことを伝える。

## 外側の棚卸し / Outer inventory（`outer`）

外側のシナリオが緑になった直後に、そのシナリオの内側で書いたテストを見直す。
1. **残す:** 境界のテスト（`tdd.tests` の種類のうち、外から見える応答や表示を確かめるもの）と、純粋関数・エラーの文言・端の入力のテスト。
2. **消してよい:** 内部の構造を固定しているだけで、外側のシナリオか境界のテストが同じことを守っているテスト。
   消すものごとに、**同じことを守っているテストの名前**を報告に書く。迷ったら残す。
3. 消したら速いスイートを全体で走らせ、緑を確かめる。消すものが無ければ何もしない。
4. 消したテストは、振る舞いの変更と分けて `test` の 1 コミットにする（`commit.md`）。
Keep boundary tests and pure-function, error-text and edge tests; delete only tests that pin internals already guarded elsewhere,
naming the guard for each. When in doubt, keep it.

**しないこと / Never:** テストの追加・削除・期待値の変更、機能の追加、「ついで」の周りの修正、まとめて直して最後に 1 回だけ走らせること。
例外は、type 2 での未コミットの新しいテスト 1 本の取り消しと、外側の棚卸しでの削除だけ。
The only exceptions are type 2 undoing the single uncommitted new test and the outer inventory.
