# C# — isolation の見本 / Isolation examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## ISO-1 テナントでの絞り込み
```csharp
// ❌ ID だけで探す（別の店の注文に届く）
await db.Orders.FindAsync(id);
// ✅ 店でも絞る（グローバルのクエリフィルターで絞るなら、IgnoreQueryFilters の箇所を疑う）
await db.Orders.SingleOrDefaultAsync(o => o.Id == id && o.ShopId == tenant.ShopId);
```

## ISO-3 キーにテナントが入っているか
```csharp
// ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
cache.Set($"price:{itemId}", price);
// ✅ 店の ID をキーに入れる
cache.Set($"price:{shopId}:{itemId}", price);
```

## ISO-6 テストのデータの独立
```csharp
// ❌ クラスで共有する DB に、ほかのテストが作った行の数で頼る
[Fact] public void ListsOrders() => Assert.Equal(3, service.List().Count);
// ✅ テストごとに別の DB（またはトランザクションの巻き戻し）を使い、要るものはテストの中で作る
[Fact] public async Task ListsOrders() {
    await using var db = TestDb.CreateFresh();
    var shop = Seed.Shop(db); Seed.Orders(db, shop, 3);
    Assert.Equal(3, new OrderService(db).ListFor(shop.Id).Count);
}
```
