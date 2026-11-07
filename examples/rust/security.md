# Rust — security の見本 / Security examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## SEC-2 テナント分離
```rust
// ❌ ID だけで探す（別の店の注文に届く）
sqlx::query_as!(Order, "SELECT * FROM orders WHERE id = $1", id)
// ✅ 店の ID でも絞る（合わなければ見つからない扱い）
sqlx::query_as!(Order, "SELECT * FROM orders WHERE id = $1 AND shop_id = $2", id, shop_id)
```

## SEC-4 エラーで内部を漏らさない
```rust
// ❌ 依存先のエラーの文字列をそのまま応答に入れる
Err(e) => HttpResponse::InternalServerError().body(e.to_string())
// ✅ 中はログに、外には決まった文言だけ
Err(e) => { tracing::error!(error = ?e, "order failed"); HttpResponse::InternalServerError().body("注文を受け付けられませんでした") }
```

## SEC-6 組み立ての注入
```rust
// ❌ format! で SQL を組み立てる
sqlx::query(&format!("SELECT * FROM seedlings WHERE name LIKE '%{q}%'"))
// ✅ バインドする
sqlx::query("SELECT * FROM seedlings WHERE name LIKE $1").bind(format!("%{q}%"))
```
