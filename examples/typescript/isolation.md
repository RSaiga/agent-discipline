# TypeScript — isolation の見本 / Isolation examples

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## ISO-1 テナントでの絞り込み
```ts
// ❌ ID だけで探す（別の店の注文に届く）
const order = await db.order.findUnique({ where: { id } })
// ✅ 店の ID でも絞る（合わなければ見つからない扱い）
const order = await db.order.findFirst({ where: { id, shopId: session.shopId } })
```

## ISO-3 キーにテナントが入っているか
```ts
// ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
cache.set(`price:${itemId}`, price)
// ✅ 店の ID をキーに入れる
cache.set(`price:${shopId}:${itemId}`, price)
```

## ISO-6 テストのデータの独立
```ts
// ❌ ファイルの中で 1 つのアプリを共有し、前のテストが足した行に頼る（そのテストだけ走らせると落ちる）
const app = createApp(openStore(':memory:'))
test('注文を足す', async () => { await app.post('/orders', { item: 'バラ' }) })
test('一覧に 1 件', async () => { expect(await app.get('/orders')).toHaveLength(1) })
// ✅ テストごとに空から作り、要るものはそのテストの中で用意する
test('一覧に 1 件', async () => {
  const app = createApp(openStore(':memory:'))
  await app.post('/orders', { item: 'バラ' })
  expect(await app.get('/orders')).toHaveLength(1)
})
```

## ISO-7 テストが変えて戻さない共有の状態
```ts
// ❌ process.env を変えたまま戻さない（同じプロセスの後のテストに漏れる）
process.env.TAX_RATE = '0.1'
// ✅ 前の値を覚えて、終わったら戻す
const before = process.env.TAX_RATE
beforeEach(() => { process.env.TAX_RATE = '0.1' })
afterEach(() => { if (before === undefined) delete process.env.TAX_RATE; else process.env.TAX_RATE = before })
```
