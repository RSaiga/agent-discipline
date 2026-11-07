# Rust — concurrency の見本 / Concurrency examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.
借用の検査はデータ競合を防ぐが、要求をまたぐ論理の競合は防がない。 / The borrow checker stops data races, not logical races across requests.

## CON-1 確かめてから実行するまでの競合
```rust
// ❌ 読んでから、別の文で減らす（2 つの要求が同じ在庫を見る）
let n: i32 = sqlx::query_scalar("SELECT n FROM stock WHERE id = $1").bind(id).fetch_one(&pool).await?;
if n > 0 { sqlx::query("UPDATE stock SET n = $2 WHERE id = $1").bind(id).bind(n - 1).execute(&pool).await?; }
// ✅ 条件つきの 1 つの更新にする
let done = sqlx::query("UPDATE stock SET n = n - 1 WHERE id = $1 AND n > 0").bind(id).execute(&pool).await?.rows_affected() == 1;
```

## CON-3 トランザクションの範囲
```rust
// ❌ 注文と在庫を別々に書く（途中で失敗すると片方だけ残る）
create_order(&pool, &o).await?; decrement_stock(&pool, o.item).await?;
// ✅ 1 つのトランザクションにまとめる
let mut tx = pool.begin().await?; create_order(&mut *tx, &o).await?; decrement_stock(&mut *tx, o.item).await?; tx.commit().await?;
```

## CON-7 後勝ち
```rust
// ❌ 読んだ版を確かめずに上書きする（同時の編集が黙って消える）
sqlx::query("UPDATE notes SET body = $2 WHERE id = $1").bind(id).bind(body)
// ✅ 版を条件にして、合わなければ衝突として返す
sqlx::query("UPDATE notes SET body = $2, version = version + 1 WHERE id = $1 AND version = $3").bind(id).bind(body).bind(read_version)
```
