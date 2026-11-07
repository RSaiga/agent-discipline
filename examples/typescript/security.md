# TypeScript — security の見本 / Security examples

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## SEC-1 認可
```ts
// ❌ 受け取った ID の注文を、誰のものか確かめずに返す
app.get('/orders/:id', async (req) => db.order.find(req.params.id))
// ✅ 呼び出した人の注文の中から探す（無ければ 404。存在を漏らさない）
app.get('/orders/:id', async (req) => db.order.findFirst({ where: { id: req.params.id, customerId: req.user.id } }) ?? notFound())
```

## SEC-4 エラーで内部を漏らさない
```ts
// ❌ 生のエラーをそのまま返す（SQL やスタックが出る）
catch (e) { return Response.json({ error: String(e), stack: e.stack }, { status: 500 }) }
// ✅ 中はログに、外には決まった文言だけ
catch (e) { log.error('order failed', e); return Response.json({ error: '注文を受け付けられませんでした' }, { status: 500 }) }
```

## SEC-6 組み立ての注入
```ts
// ❌ 外からの値を SQL に連結する（`' OR '1'='1` で全件が返る）
db.query(`SELECT * FROM seedlings WHERE name LIKE '%${q}%'`).all()
// ✅ プレースホルダで渡す
db.query('SELECT * FROM seedlings WHERE name LIKE ?').all(`%${q}%`)
```
