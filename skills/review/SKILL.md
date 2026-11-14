---
name: review
description: Review through the lenses, read-only. No argument reviews the working change; a branch, commit range or pull request URL reviews that diff; files or directories review the code itself. Add --second for a second opinion from another AI.
disable-model-invocation: true
---

プラグインの根元 / Plugin root: `${CLAUDE_PLUGIN_ROOT}`（置き換わっていなければ、この SKILL.md の 2 つ上のディレクトリ / if not substituted, two directories above this SKILL.md）。以下のパスはすべてここからの相対パス。 / All paths below are relative to it.

最初の 1 回の往復で、次を**まとめて**行う:
- `procedures/discipline.md` と `procedures/review.md` を読む。
- `git rev-parse --show-toplevel; cat .codence/profile.md .codence/config.yaml` を、プラグインではなく**プロジェクトの現在のディレクトリで**実行する（現在のディレクトリが根元でなく読めなかったときだけ、根元のパスで読み直す）。

そのあと、動く条件を確かめてから `procedures/review.md` を実行する。呼び出しに続く文字列があれば、レビューの対象の指定として扱う。`--second` があれば、それを対象から外し、`procedures/second-opinion.md` も読んで従う。

In the first turn, together: read `procedures/discipline.md` and `procedures/review.md`, and run the command above in the project's
current directory, not the plugin (re-read with the root path only if the current directory is not the root). Then check the activation conditions and run
`procedures/review.md`. Any text after the invocation names the review target; `--second` is not part of it and means: also follow `procedures/second-opinion.md`.
