# PHP — isolation の見本 / Isolation examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.


## ISO-1 テナントでの絞り込み
```php
// ❌ ID だけで探す（別の店の注文に届く）
Order::findOrFail($id);
// ✅ 店でも絞る（グローバルスコープで店を自動で絞る形も可。その場合は、外す箇所を疑う）
Order::where('shop_id', $request->user()->shop_id)->findOrFail($id);
```

## ISO-3 キーにテナントが入っているか
```php
// ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
Cache::put("price:{$itemId}", $price);
// ✅ 店の ID をキーに入れる
Cache::put("price:{$shopId}:{$itemId}", $price);
```

## ISO-6 テストのデータの独立
```php
// ❌ ほかのテストが作った行の数に頼る
public function test_list() { $this->assertCount(3, Order::all()); }
// ✅ RefreshDatabase で毎回空から始め、要るものはテストの中で作る
use RefreshDatabase;
public function test_list() { $shop = Shop::factory()->create(); Order::factory()->count(3)->for($shop)->create(); $this->assertCount(3, $shop->orders); }
```
