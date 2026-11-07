# Python — isolation の見本 / Isolation examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## ISO-1 テナントでの絞り込み
```python
# ❌ ID だけで探す（別の店の注文に届く）
order = Order.objects.get(pk=order_id)
# ✅ 店でも絞る（合わなければ見つからない扱い）
order = get_object_or_404(Order, pk=order_id, shop=request.user.shop)
```

## ISO-3 キーにテナントが入っているか
```python
# ❌ キャッシュのキーが商品の ID だけ（店ごとの価格が混ざる）
cache.set(f"price:{item_id}", price)
# ✅ 店の ID をキーに入れる
cache.set(f"price:{shop_id}:{item_id}", price)
```

## ISO-6・ISO-7 テストの独立
```python
# ❌ モジュールの範囲の fixture を共有し、前のテストが足した行に頼る。環境変数を変えたまま戻さない
@pytest.fixture(scope="module")
def db(): ...
def test_list(db):
    os.environ["TAX_RATE"] = "0.1"
    assert len(list_orders(db)) == 3
# ✅ テストごとの fixture で空から作る。環境変数は monkeypatch で変える（終われば戻る）
@pytest.fixture
def db(): ...
def test_list(db, monkeypatch):
    monkeypatch.setenv("TAX_RATE", "0.1")
    shop = make_shop(db); make_orders(db, shop, 3)
    assert len(list_orders(db, shop)) == 3
```
