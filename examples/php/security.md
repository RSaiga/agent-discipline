# PHP — security の見本 / Security examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.


## SEC-1 認可
```php
// ❌ 受け取った ID の注文を、誰のものか確かめずに返す
public function show(int $id) { return Order::findOrFail($id); }
// ✅ 呼び出した人の注文の中から探す（無ければ 404。存在を漏らさない）
public function show(Request $request, int $id) { return $request->user()->orders()->findOrFail($id); }
```

## SEC-4 エラーで内部を漏らさない
```php
// ❌ 例外のメッセージとトレースを応答に入れる
catch (\Throwable $e) { return response()->json(['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()], 500); }
// ✅ 中はログに、外には決まった文言だけ（本番では APP_DEBUG=false）
catch (\Throwable $e) { Log::error('order failed', ['exception' => $e]); return response()->json(['error' => '注文を受け付けられませんでした'], 500); }
```

## SEC-6 組み立ての注入
```php
// ❌ 外からの値を SQL に連結する
DB::select("SELECT * FROM seedlings WHERE name LIKE '%$q%'");
// ✅ バインドする
DB::select('SELECT * FROM seedlings WHERE name LIKE ?', ["%{$q}%"]);
```
