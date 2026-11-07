# C# — concurrency の見本 / Concurrency examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## CON-1 確かめてから実行するまでの競合
```csharp
// ❌ 在庫を読んでから、await をはさんで減らす（2 つの要求が同じ在庫を見て、両方とも通る）
var s = await db.Stocks.FindAsync(id);
if (s.N > 0) { s.N--; await db.SaveChangesAsync(); }
// ✅ 条件つきの 1 つの更新にする（または同時実行のトークンで楽観ロック）
var ok = await db.Stocks.Where(x => x.Id == id && x.N > 0).ExecuteUpdateAsync(u => u.SetProperty(x => x.N, x => x.N - 1)) == 1;
```

## CON-3 トランザクションの範囲
```csharp
// ❌ 注文と在庫を別々に保存する（途中で失敗すると片方だけ残る）
db.Orders.Add(order); await db.SaveChangesAsync();
await db.Stocks.Where(x => x.Id == order.ItemId).ExecuteUpdateAsync(u => u.SetProperty(x => x.N, x => x.N - 1));
// ✅ 1 つのトランザクションにまとめる
await using var tx = await db.Database.BeginTransactionAsync();
db.Orders.Add(order); await db.SaveChangesAsync();
await db.Stocks.Where(x => x.Id == order.ItemId).ExecuteUpdateAsync(u => u.SetProperty(x => x.N, x => x.N - 1));
await tx.CommitAsync();
```

## CON-5 プロセス全体で共有する状態
```csharp
// ❌ Singleton のサービスのフィールドに、要求ごとの値を置く（別の客の結果が返る）
public class CartService { private Cart? last; public Cart Get(User u) => last ??= Load(u); }
// ✅ 要求の中に閉じ込める（Scoped にするか、利用者をキーにして ConcurrentDictionary で守る）
public class CartService { public Cart Get(User u) => Load(u); }
```
