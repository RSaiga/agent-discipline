# Ruby — isolation の見本 / Isolation examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## ISO-1 テナントでの絞り込み
```ruby
# ❌ ID だけで探す（別の店の注文に届く）
Order.find(params[:id])
# ✅ 店の関連から探す（default_scope で絞るなら、unscoped で外す箇所を疑う）
Current.shop.orders.find(params[:id])
```

## ISO-3 キーにテナントが入っているか
```ruby
# ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
Rails.cache.fetch(["price", item_id]) { compute_price(item_id) }
# ✅ 店の ID をキーに入れる
Rails.cache.fetch(["price", shop_id, item_id]) { compute_price(shop_id, item_id) }
```

## ISO-6・ISO-7 テストの独立
```ruby
# ❌ ほかのテストが作った行の数に頼る。ENV を変えたまま戻さない
it "lists orders" do
  ENV["TAX_RATE"] = "0.1"
  expect(Order.count).to eq 3
end
# ✅ テストの中で作り（トランザクションの巻き戻しで片付く）、ENV は stub する
it "lists orders" do
  stub_const("ENV", ENV.to_h.merge("TAX_RATE" => "0.1"))
  shop = create(:shop); create_list(:order, 3, shop: shop)
  expect(shop.orders.count).to eq 3
end
```
