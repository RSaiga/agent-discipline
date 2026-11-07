# リファクタリングのカタログ / Refactoring catalog

キットの汎用の出発点。プロジェクトに自分の規約やカタログがあれば、そちらを使う。このファイルは、育てるか置き換える。
上から順に疑う。匂いの名前と直し方を言う。リファクタのあいだは振る舞いを変えない。
A starter catalog shipped with the kit; prefer the project's own. Suspect these in order, name the smell and the move,
and never change behaviour while refactoring.

## Duplicated Code
同じ規則や計算が 2 か所にある。直し方: 1 つの関数か型に置き、両方からそれを呼ぶ。
The same rule or calculation in two places. Move: keep it in one function or type and call it.

## Feature Envy
ほかのモジュールのデータばかり読む関数。直し方: その処理をデータのそばへ移す。
A function that mostly reads another module's data. Move: put the logic next to that data.

## Long Function
いくつものことを順にしている関数。直し方: 段ごとに名前を付けて切り出す。
A function doing several things one after another. Move: extract each step with a name.

## Mysterious Name
何のためのものかを語らない名前。直し方: 目的に合わせて名前を変える。
A name that does not say what the thing is for. Move: rename it after its purpose.

## Data Clumps
いつも一緒に渡される値の組。直し方: 1 つの型にまとめる。
Values that always travel together. Move: gather them into one type.

## Primitive Obsession
意味と規則を持つ値が、素の文字列や数値のまま扱われている。直し方: 規則を持つ小さな型にする。
A value with meaning and rules handled as a bare string or number. Move: give it a small type that holds the rules.
