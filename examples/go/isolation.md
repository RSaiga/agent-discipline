# Go — isolation の見本 / Isolation examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## ISO-1 テナントでの絞り込み
```go
// ❌ ID だけで探す（別の店の注文に届く）
db.First(&o, id)
// ✅ 店の ID でも絞る（合わなければ見つからない扱い）
db.Where("id = ? AND shop_id = ?", id, shopID).First(&o)
```

## ISO-3 キーにテナントが入っているか
```go
// ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
key := fmt.Sprintf("price:%d", itemID)
// ✅ 店の ID をキーに入れる
key := fmt.Sprintf("price:%d:%d", shopID, itemID)
```

## ISO-6 テストのデータの独立
```go
// ❌ ほかのテストが作った行の数に頼る（順番や並列で結果が変わる）
func TestListOrders(t *testing.T) {
	orders := listOrders(testDB)
	assert.Len(t, orders, 3)
}
// ✅ テストの中で自分の店を作り、その店の中だけを数える
func TestListOrders(t *testing.T) {
	shop := createShop(t, testDB) // t.Cleanup で片付ける
	createOrders(t, testDB, shop.ID, 3)
	assert.Len(t, listOrdersFor(testDB, shop.ID), 3)
}
```

## ISO-7 テストが変えて戻さない共有の状態
```go
// ❌ os.Setenv で変えたまま戻さない（後のテストや並列のテストに漏れる）
os.Setenv("TAX_RATE", "0.1")
// ✅ t.Setenv はテストの終わりに戻す（t.Parallel とは併用できないことも守ってくれる）
t.Setenv("TAX_RATE", "0.1")
```
