# retro — 振り返りを 1 件残す / Record one retrospective

書いてよいのは `<根元>/.agent-discipline/findings.md` だけ。無ければ作る。追記だけで、既存の行は変えない。
Write only to `<root>/.agent-discipline/findings.md`; create it if missing; append only.

呼び出しに `track` が付いていたら、下の「対策を追う」だけを行う。 / With `track`, run only "Track countermeasures" below.

1. この会話でしたことから、次の 3 つを短く書く。分からないものは「不明」と書く（推測で埋めない）。
   - **意図**: 何をしようとしていたか / What was intended
   - **結果**: 何が起きたか（テストや観点の結果は、実際の出力から） / What happened, from actual output
   - **止まった箇所**: どこで、なぜ止まったか。止まらなかったなら「なし」 / Where and why work stopped, or "none"
   次の 2 つは、決まっているときだけ書く（決まっていなければ行ごと書かない）。
   - **対策**: 何を変えたか、変えるか（キットの手順・設定・プロジェクトの規約）
   - **確かめ方**: どの結果を見れば効いたと言えるか（例: 次の 3 回の `tdd-cycle` で同じ理由で止まらない）
2. この形で末尾に足す（番号 `F<n>` は、ファイルの中で最大の番号 + 1）:
   ```
   ## F<n> <YYYY-MM-DD> <一言の題>
   - 意図: …
   - 結果: …
   - 止まった箇所: …
   - 対策: …（あれば）
   - 確かめ方: …（あれば）
   ```
3. 足した内容をそのまま報告する。 / Report the appended entry verbatim.

## 対策を追う / Track countermeasures（`track`）

1. `findings.md` を読み、`対策` と `確かめ方` のある記録のうち、まだ「追跡」の記録が無いもの（または前の判定が「未判定」のもの）を選ぶ。
2. それぞれについて、`確かめ方` が指す結果を見る。証拠は、その記録より**後**の記録と、`確かめ方` が名指しするファイル（テストや bench の出力）だけ。
   推測で埋めない。
   - **効いた**: 確かめ方の条件を満たし、同じ理由で止まった記録が後に無い。
   - **再発した**: 後の記録に、同じ理由で止まった（同じ問題が起きた）ものがある。どの記録かを書く。
   - **未判定**: 証拠が足りない（後の記録が確かめ方の回数に届かない、ファイルが無い）。何が足りないかを書く。
3. 判定ごとに末尾に足す（元の記録は書き換えない）:
   ```
   ## <YYYY-MM-DD> 追跡 F<n>
   - 判定: 効いた / 再発した / 未判定
   - 根拠: <どの記録・どのファイルの、どの内容から>
   ```
4. 足した内容をそのまま報告する。対策のある記録が無ければ、そう伝えて何も足さない。
For each finding with a countermeasure and a check, judge from later entries and named files only: worked, recurred, or undetermined.
Append a tracking entry; never edit the original.
