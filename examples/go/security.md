# Go — security の見本 / Security examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## SEC-1 認可
```go
// ❌ 受け取った ID の注文を、誰のものか確かめずに返す
func (h *Handler) GetOrder(c *gin.Context) {
	var o Order
	h.db.First(&o, c.Param("id"))
	c.JSON(http.StatusOK, o)
}
// ✅ 呼び出した人の注文の中から探す（無ければ 404。存在を漏らさない）
func (h *Handler) GetOrder(c *gin.Context) {
	var o Order
	if err := h.db.Where("id = ? AND customer_id = ?", c.Param("id"), currentUser(c).ID).First(&o).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "注文が見つかりません"})
		return
	}
	c.JSON(http.StatusOK, o)
}
```

## SEC-4 エラーで内部を漏らさない
```go
// ❌ 依存先のエラーの文字列をそのまま応答に入れる（SQL や制約の名前が出る）
if err != nil {
	c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	return
}
// ✅ 中はログに、外には決まった文言だけ
if err != nil {
	log.Printf("order failed: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "注文を受け付けられませんでした"})
	return
}
```

## SEC-6 組み立ての注入
```go
// ❌ 外からの値を SQL に連結する（`' OR '1'='1` で全件が返る）
h.db.Raw(fmt.Sprintf("SELECT * FROM seedlings WHERE name LIKE '%%%s%%'", q)).Scan(&rows)
// ✅ プレースホルダで渡す
h.db.Where("name LIKE ?", "%"+q+"%").Find(&rows)
```
