# Java — security の見本 / Security examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.
Kotlin でも同じ書き方で読める。 / The same idioms apply to Kotlin.

## SEC-1 認可
```java
// ❌ 受け取った ID の注文を、誰のものか確かめずに返す
@GetMapping("/orders/{id}")
Order get(@PathVariable long id) { return orders.findById(id).orElseThrow(); }
// ✅ 呼び出した人の注文の中から探す（無ければ 404。存在を漏らさない）
@GetMapping("/orders/{id}")
Order get(@PathVariable long id, @AuthenticationPrincipal Customer me) {
    return orders.findByIdAndCustomerId(id, me.getId()).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
}
```

## SEC-4 エラーで内部を漏らさない
```java
// ❌ 例外のメッセージとスタックを応答に入れる
@ExceptionHandler(Exception.class)
ResponseEntity<Map<String, String>> handle(Exception e) {
    return ResponseEntity.status(500).body(Map.of("error", e.getMessage(), "trace", Arrays.toString(e.getStackTrace())));
}
// ✅ 中はログに、外には決まった文言だけ
@ExceptionHandler(Exception.class)
ResponseEntity<Map<String, String>> handle(Exception e) {
    log.error("order failed", e);
    return ResponseEntity.status(500).body(Map.of("error", "注文を受け付けられませんでした"));
}
```

## SEC-6 組み立ての注入
```java
// ❌ 文字列の連結で JPQL を組み立てる
em.createQuery("SELECT s FROM Seedling s WHERE s.name LIKE '%" + q + "%'", Seedling.class)
// ✅ パラメータで渡す
em.createQuery("SELECT s FROM Seedling s WHERE s.name LIKE :q", Seedling.class).setParameter("q", "%" + q + "%")
```
