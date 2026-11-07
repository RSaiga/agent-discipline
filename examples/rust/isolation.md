# Rust — isolation の見本 / Isolation examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## ISO-1 テナントでの絞り込み
```rust
// ❌ ID だけで探す（別の店の注文に届く）
sqlx::query_as!(Order, "SELECT * FROM orders WHERE id = $1", id)
// ✅ 店の ID でも絞る（合わなければ見つからない扱い）
sqlx::query_as!(Order, "SELECT * FROM orders WHERE id = $1 AND shop_id = $2", id, shop_id)
```

## ISO-3 キーにテナントが入っているか
```rust
// ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
cache.insert(item_id, price);
// ✅ 店の ID をキーに入れる
cache.insert((shop_id, item_id), price);
```

## ISO-7 テストが変えて戻さない共有の状態
```rust
// ❌ 環境変数を変える（cargo test はテストを並べて走らせるので、同じプロセスのほかのテストに漏れる）
std::env::set_var("TAX_RATE", "0.1");
// ✅ 値を引数で渡す設計にする。どうしても環境変数を使うなら、そのテストを 1 つずつ走らせる（serial_test など）
let config = Config { tax_rate: 0.1, ..Config::default() };
```

## ISO-8 テストの並列実行の取り合い
```rust
// ❌ 固定の ID の行を、並べて走るテストが取り合う
sqlx::query!("INSERT INTO shops (id, name) VALUES (1, 'test')").execute(&pool).await?;
// ✅ テストごとに別の行を作り、そのテストの中だけで使う（またはテストごとのトランザクションを巻き戻す）
let shop_id = create_shop(&pool, &format!("test-{}", uuid::Uuid::new_v4())).await?;
```
