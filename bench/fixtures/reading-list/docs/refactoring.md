# Refactoring catalog

Suspect these in order. Name the smell and the move; never change behaviour while refactoring.

## Duplicated Code
The same rule or calculation in two places. Move: keep it in one function or type and call it.

## Feature Envy
A function that mostly reads another module's data. Move: put the logic next to that data.

## Long Function
A function doing several things one after another. Move: extract each step with a name.

## Mysterious Name
A name that does not say what the thing is for. Move: rename it after its purpose.
