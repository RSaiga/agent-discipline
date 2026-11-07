# Ruby — security の見本 / Security examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## SEC-1 認可
```ruby
# ❌ 受け取った ID の注文を、誰のものか確かめずに返す
def show = render json: Order.find(params[:id])
# ✅ 呼び出した人の注文の中から探す（無ければ 404。存在を漏らさない）
def show = render json: current_user.orders.find(params[:id])
```

## SEC-4 エラーで内部を漏らさない
```ruby
# ❌ 例外のメッセージとバックトレースを応答に入れる
rescue => e
  render json: { error: e.message, trace: e.backtrace }, status: 500
# ✅ 中はログに、外には決まった文言だけ
rescue => e
  Rails.logger.error(e.full_message)
  render json: { error: "注文を受け付けられませんでした" }, status: 500
```

## SEC-6 組み立ての注入
```ruby
# ❌ 外からの値を SQL に補間する
Seedling.where("name LIKE '%#{params[:q]}%'")
# ✅ プレースホルダで渡す
Seedling.where("name LIKE ?", "%#{Seedling.sanitize_sql_like(params[:q])}%")
```
