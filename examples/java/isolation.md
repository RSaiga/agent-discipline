# Java — isolation の見本 / Isolation examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.
Kotlin でも同じ書き方で読める。 / The same idioms apply to Kotlin.

## ISO-1 テナントでの絞り込み
```java
// ❌ ID だけで探す（別の店の注文に届く）
orders.findById(id)
// ✅ 店の ID でも絞る（合わなければ見つからない扱い）
orders.findByIdAndShopId(id, currentShopId())
```

## ISO-3 キーにテナントが入っているか
```java
// ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
@Cacheable(value = "price", key = "#itemId")
// ✅ 店の ID をキーに入れる
@Cacheable(value = "price", key = "#shopId + ':' + #itemId")
```

## ISO-6 テストのデータの独立
```java
// ❌ ほかのテストが作った行の数に頼る（実行の順番で結果が変わる）
@Test void listsOrders() { assertThat(service.list()).hasSize(3); }
// ✅ テストの中で自分の店と注文を作り、@Transactional でテストの終わりに巻き戻す
@Test @Transactional void listsOrders() {
    Shop shop = shops.save(new Shop("test"));
    orders.saveAll(List.of(new Order(shop), new Order(shop), new Order(shop)));
    assertThat(service.listFor(shop.getId())).hasSize(3);
}
```
