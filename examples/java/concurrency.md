# Java — concurrency の見本 / Concurrency examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.
Kotlin でも同じ書き方で読める。 / The same idioms apply to Kotlin.

## CON-1 確かめてから実行するまでの競合
```java
// ❌ 在庫を読んでから減らす（既定の分離レベルでは、2 つの要求が同じ在庫を見て両方とも通る）
Stock s = stocks.findById(id).orElseThrow();
if (s.getN() > 0) { s.setN(s.getN() - 1); stocks.save(s); }
// ✅ 条件つきの 1 つの更新にする（または @Version で楽観ロック）
@Modifying @Query("UPDATE Stock s SET s.n = s.n - 1 WHERE s.id = :id AND s.n > 0")
int decrement(@Param("id") long id);
```

## CON-3 トランザクションの範囲
```java
// ❌ 同じクラスの中から @Transactional のメソッドを呼ぶ（プロキシを通らず、トランザクションが掛からない）
public void place(Order o) { saveOrderAndStock(o); }
@Transactional void saveOrderAndStock(Order o) { orders.save(o); stocks.decrement(o.getItemId()); }
// ✅ トランザクションの境界を、外から呼ばれる public のメソッドに置く
@Transactional public void place(Order o) { orders.save(o); stocks.decrement(o.getItemId()); }
```

## CON-5 プロセス全体で共有する状態
```java
// ❌ シングルトンの Bean のフィールドに、要求ごとの値を置く（別の客の結果が返る）
@Service class CartService { private Cart last; Cart cart(User u) { if (last == null) last = load(u); return last; } }
// ✅ 要求の中に閉じ込める（キャッシュするなら利用者をキーにし、ConcurrentHashMap などで守る）
@Service class CartService { Cart cart(User u) { return load(u); } }
```
