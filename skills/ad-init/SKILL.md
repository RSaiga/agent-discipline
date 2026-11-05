---
name: ad-init
description: Set up agent-discipline for this project: draft .agent-discipline/profile.md and config.yaml.
disable-model-invocation: true
---

プラグインの根元 / Plugin root: `${CLAUDE_PLUGIN_ROOT}`（置き換わっていなければ、この SKILL.md の 2 つ上のディレクトリ / if not substituted, two directories above this SKILL.md）。以下のパスはすべてここからの相対パス。 / All paths below are relative to it.

`procedures/init.md` を実行する。`procedures/discipline.md` の「動く条件」は確かめない（このスキルがその条件を作る）。
Run `procedures/init.md`. Skip the activation check in `procedures/discipline.md` — this skill is what creates those conditions.
