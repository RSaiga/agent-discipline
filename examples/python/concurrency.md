# Python — concurrency の見本 / Concurrency examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.
GIL は Python のオブジェクトを守るが、await や DB をはさんだ論理の競合は防がない。 / The GIL does not prevent logical races across awaits or the database.

## CON-1 確かめてから実行するまでの競合
```python
# ❌ 在庫を読んでから、await をはさんで減らす（2 つの要求が同じ在庫を見て、両方とも通る）
stock = await repo.get_stock(item_id)
await audit(item_id)
if stock > 0:
    await repo.set_stock(item_id, stock - 1)
# ✅ 条件つきの 1 つの更新にする
result = await session.execute(update(Stock).where(Stock.id == item_id, Stock.n > 0).values(n=Stock.n - 1))
ok = result.rowcount == 1
```

## CON-2 冪等性
```python
# ❌ 支払いの通知が届くたびに出荷を作る（再送で 2 つ出荷される）
def on_paid(event):
    Shipment.objects.create(order_id=event["order_id"])
# ✅ 通知の ID で一度だけにする（一意の制約で 2 回目を弾く）
def on_paid(event):
    Shipment.objects.get_or_create(event_id=event["id"], defaults={"order_id": event["order_id"]})
```

## CON-5 プロセス全体で共有する状態
```python
# ❌ モジュールの変数に要求ごとの値を置く（別の客の結果が返る）
_last_cart = None
def cart(user):
    global _last_cart
    if _last_cart is None:
        _last_cart = load(user)
    return _last_cart
# ✅ 要求の中に閉じ込める（キャッシュするなら利用者をキーに入れる）
def cart(user):
    return load(user)
```
