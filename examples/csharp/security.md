# C# — security の見本 / Security examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## SEC-1 認可
```csharp
// ❌ 受け取った ID の注文を、誰のものか確かめずに返す
app.MapGet("/orders/{id}", (int id, AppDb db) => db.Orders.Find(id));
// ✅ 呼び出した人の注文の中から探す（無ければ 404。存在を漏らさない）
app.MapGet("/orders/{id}", async (int id, ClaimsPrincipal me, AppDb db) =>
    await db.Orders.SingleOrDefaultAsync(o => o.Id == id && o.CustomerId == me.CustomerId()) is { } o ? Results.Ok(o) : Results.NotFound());
```

## SEC-4 エラーで内部を漏らさない
```csharp
// ❌ 例外の文字列をそのまま応答に入れる
catch (Exception e) { return Results.Problem(e.ToString()); }
// ✅ 中はログに、外には決まった文言だけ
catch (Exception e) { logger.LogError(e, "order failed"); return Results.Problem("注文を受け付けられませんでした"); }
```

## SEC-6 組み立ての注入
```csharp
// ❌ 補間した文字列を FromSqlRaw に渡す
db.Seedlings.FromSqlRaw($"SELECT * FROM seedlings WHERE name LIKE '%{q}%'");
// ✅ FromSql（補間はパラメータになる）か LINQ で書く
db.Seedlings.Where(s => EF.Functions.Like(s.Name, $"%{q}%"));
```
