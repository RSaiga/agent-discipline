# Go — concurrency の見本 / Concurrency examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.
goroutine は要求ごとに並んで動く。`go test -race` はデータ競合を見つけるが、DB をはさんだ論理の競合は見つけない。
Handlers run in parallel goroutines; the race detector finds data races, not logical races through the database.

## CON-1 確かめてから実行するまでの競合
```go
// ❌ 在庫を読んでから、別の文で減らす（2 つの要求が同じ在庫を見て、両方とも通る）
var s Stock
db.First(&s, id)
if s.N > 0 {
	s.N--
	db.Save(&s)
}
// ✅ 条件つきの 1 つの更新にする（成り立たなければ 0 件）
res := db.Model(&Stock{}).Where("id = ? AND n > 0", id).UpdateColumn("n", gorm.Expr("n - 1"))
ok := res.RowsAffected == 1
```

## CON-3 トランザクションの範囲
```go
// ❌ 注文と在庫を別々に書く（途中で失敗すると片方だけ残る）
db.Create(&order)
db.Model(&Stock{}).Where("id = ?", order.ItemID).UpdateColumn("n", gorm.Expr("n - 1"))
// ✅ 1 つのトランザクションにまとめる
err := db.Transaction(func(tx *gorm.DB) error {
	if err := tx.Create(&order).Error; err != nil {
		return err
	}
	return tx.Model(&Stock{}).Where("id = ?", order.ItemID).UpdateColumn("n", gorm.Expr("n - 1")).Error
})
```

## CON-5 プロセス全体で共有する状態
```go
// ❌ パッケージの変数に、要求ごとの値を守りなしで置く（データ競合で壊れ、別の客の結果も返る）
var lastCart map[string]Cart

func cart(user string) Cart {
	if c, ok := lastCart["last"]; ok {
		return c
	}
	c := load(user)
	lastCart["last"] = c
	return c
}
// ✅ 要求の中に閉じ込める（キャッシュするなら利用者をキーにし、sync.Mutex か sync.Map で守る）
func cart(user string) Cart { return load(user) }
```
