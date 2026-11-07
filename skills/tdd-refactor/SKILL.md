---
name: tdd-refactor
description: TDD refactor: restructure while green, without changing behavior or assertions.
disable-model-invocation: true
---

プラグインの根元 / Plugin root: `${CLAUDE_PLUGIN_ROOT}`（置き換わっていなければ、この SKILL.md の 2 つ上のディレクトリ / if not substituted, two directories above this SKILL.md）。以下のパスはすべてここからの相対パス。 / All paths below are relative to it.

最初の 1 回の往復で、次を**まとめて**行う:
- `procedures/discipline.md`、`procedures/tdd.md`、`procedures/refactor.md` を読む。
- `git rev-parse --show-toplevel; git branch --show-current; cat .agent-discipline/profile.md .agent-discipline/config.yaml` を、プラグインではなく**プロジェクトの現在のディレクトリで**実行する（現在のディレクトリが根元でなく読めなかったときだけ、根元のパスで読み直す）。

次の往復で、`.agent-discipline/lists/<ブランチ>.md`（ブランチ名の `/` は `-`）と `profile.md` の `tdd.rules` の規約、`lenses/structure.md` と `lenses.structure.catalog` をまとめて読む。どれもファイルとして 1 回だけ開く（リストはあとで書き換える。シェルの出力で読んだものを開き直さない）。

そのあと、動く条件を確かめてから `procedures/refactor.md` を実行する。呼び出しに続く文字列があれば、直したい箇所の指定として扱う。

In the first turn, together: read `procedures/discipline.md`, `procedures/tdd.md`, `procedures/refactor.md`, and run the command above in the project's current directory, not the plugin
(re-read with the root path only if the current directory is not the root). In the next turn, read the test list `.agent-discipline/lists/<branch>.md` (`/` in the branch name becomes `-`) and the `tdd.rules` files, plus `lenses/structure.md` and the structure catalog, together — each opened once as a file (the list is edited later; never re-open what a shell command already printed). Then check the activation conditions and run
`procedures/refactor.md`. Any text after the invocation names what to restructure.
