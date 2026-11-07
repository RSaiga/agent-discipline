# PHP — concurrency の見本 / Concurrency examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.


## CON-1 確かめてから実行するまでの競合
```php
// ❌ 在庫を読んでから、別の文で減らす（2 つの要求が同じ在庫を見て、両方とも通る）
$stock = Stock::find($id);
if ($stock->n > 0) { $stock->decrement('n'); }
// ✅ 条件つきの 1 つの更新にする
$ok = Stock::where('id', $id)->where('n', '>', 0)->decrement('n') === 1;
```

## CON-2 冪等性
```php
// ❌ キューの仕事が再実行されるたびに出荷を作る（失敗のあとの再試行で 2 つ出荷される）
public function handle() { Shipment::create(['order_id' => $this->orderId]); }
// ✅ 一意のキーで一度だけにする
public function handle() { Shipment::firstOrCreate(['order_id' => $this->orderId]); }
```

## CON-3 トランザクションの範囲
```php
// ❌ 注文と在庫を別々に書く（途中で失敗すると片方だけ残る）
Order::create($data); Stock::where('id', $data['item_id'])->decrement('n');
// ✅ 1 つのトランザクションにまとめる
DB::transaction(function () use ($data) { Order::create($data); Stock::where('id', $data['item_id'])->decrement('n'); });
```
