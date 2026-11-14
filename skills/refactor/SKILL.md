---
name: refactor
description: Restructure code outside TDD: find smells with the structure lens and fix, one at a time, only what existing tests guard.
disable-model-invocation: true
---

プラグインの根元 / Plugin root: `${CLAUDE_PLUGIN_ROOT}`（置き換わっていなければ、この SKILL.md の 2 つ上のディレクトリ / if not substituted, two directories above this SKILL.md）。以下のパスはすべてここからの相対パス。 / All paths below are relative to it.

最初の 1 回の往復で、次を**まとめて**行う:
- `procedures/discipline.md`、`procedures/review.md`、`procedures/refactor-only.md`、`procedures/refactor.md`、`procedures/commit.md`、`lenses/structure.md` を読む。
- `git rev-parse --show-toplevel; git branch --show-current; cat .codence/profile.md .codence/config.yaml` を、プラグインではなく**プロジェクトの現在のディレクトリで**実行する。

次の往復で、`lenses.structure.catalog` と `tdd.rules` の規約をまとめて読む。そのあと、動く条件を確かめてから `procedures/refactor-only.md` を実行する。
呼び出しに続く文字列があれば、対象の指定（ファイル・フォルダ・ブランチ・コミットの範囲）として扱う。

In the first turn, together: read the procedures and the structure lens above, and run the command in the project's current directory. In the next turn, read the catalog and
the `tdd.rules` files. Then check the activation conditions and run `procedures/refactor-only.md`. Text after the invocation names the target.
