# refactor — 緑のまま構造だけを直す / Restructure while green

振る舞いを変えない。テストの期待値を変えない。 / No behavior change; assertions untouched.

呼び出しに `outer` が付いていたら、下の「外側の棚卸し」だけを行う。 / With `outer`, run only the outer inventory below.

1. **緑であることを確かめる。** 直前の green の結果がまだ有効なら、それを使う。緑でなければ止まる。
2. **直近の変更を読み、直す価値のある構造の問題を挙げる。** 基準は `profile.md` の `lenses.structure.catalog`
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

## 外側の棚卸し / Outer inventory（`outer`）

外側のシナリオが緑になった直後に、そのシナリオの内側で書いたテストを見直す。
1. **残す:** 境界のテスト（`tdd.tests` の種類のうち、外から見える応答や表示を確かめるもの）と、純粋関数・エラーの文言・端の入力のテスト。
2. **消してよい:** 内部の構造を固定しているだけで、外側のシナリオか境界のテストが同じことを守っているテスト。
   消すものごとに、**同じことを守っているテストの名前**を報告に書く。迷ったら残す。
3. 消したら速いスイートを全体で走らせ、緑を確かめる。消すものが無ければ何もしない。
4. 消したテストは、振る舞いの変更と分けて `test` の 1 コミットにする（`commit.md`）。
Keep boundary tests and pure-function, error-text and edge tests; delete only tests that pin internals already guarded elsewhere,
naming the guard for each. When in doubt, keep it.

**しないこと / Never:** テストの追加・削除（外側の棚卸しを除く）・期待値の変更、機能の追加、「ついで」の周りの修正、まとめて直して最後に 1 回だけ走らせること。
