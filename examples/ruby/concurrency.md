# Ruby — concurrency の見本 / Concurrency examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## CON-1 確かめてから実行するまでの競合
```ruby
# ❌ 在庫を読んでから減らす（2 つの要求が同じ在庫を見て、両方とも通る）
stock = Stock.find(id)
stock.update!(n: stock.n - 1) if stock.n.positive?
# ✅ 条件つきの 1 つの更新にする（または lock! で行を押さえる）
ok = Stock.where(id: id).where("n > 0").update_all("n = n - 1") == 1
```

## CON-2 冪等性
```ruby
# ❌ ジョブが再実行されるたびに出荷を作る
def perform(order_id) = Shipment.create!(order_id: order_id)
# ✅ 一意の制約と find_or_create_by で一度だけにする
def perform(order_id) = Shipment.create_or_find_by!(order_id: order_id)
```

## CON-5 プロセス全体で共有する状態
```ruby
# ❌ クラスの変数に要求ごとの値を置く（スレッドをまたいで別の客の結果が返る）
class CartService
  @@last = nil
  def self.cart(user) = (@@last ||= load(user))
end
# ✅ 要求の中に閉じ込める（要求ごとの値は Current の属性に置く）
class CartService
  def self.cart(user) = load(user)
end
```
