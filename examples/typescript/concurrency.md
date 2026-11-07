# TypeScript — concurrency の見本 / Concurrency examples

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.
単一スレッドでも、`await` のたびに別の要求が割り込む。 / A single thread still interleaves at every await.

## CON-1 確かめてから実行するまでの競合
```ts
// ❌ 在庫を読んでから、await をはさんで減らす（2 つの要求が同じ在庫を見て、両方とも通る）
const stock = await db.stock.get(id); await audit(id); if (stock > 0) await db.stock.set(id, stock - 1)
// ✅ 条件つきの 1 つの更新にする（成り立たなければ 0 件）
const changed = await db.run('UPDATE stock SET n = n - 1 WHERE id = ? AND n > 0', id)
```

## CON-2 冪等性
```ts
// ❌ 支払いの通知が届くたびに出荷を作る（再送で 2 つ出荷される）
onPaid(async (ev) => db.shipment.create({ orderId: ev.orderId }))
// ✅ 通知の ID で一度だけにする（一意の制約で 2 回目を弾く）
onPaid(async (ev) => db.shipment.createIfAbsent({ eventId: ev.id, orderId: ev.orderId }))
```

## CON-5 プロセス全体で共有する状態
```ts
// ❌ モジュールの変数に要求ごとの値を置く（別の客の結果が返る）
let lastCart: Cart | undefined
export const cart = async (user: User) => (lastCart ??= await load(user))
// ✅ 要求の中に閉じ込める（キャッシュするなら利用者をキーに入れる）
export const cart = async (user: User) => load(user)
```
