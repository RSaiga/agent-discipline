# Python — security の見本 / Security examples（bench では未検証 / not yet validated by the bench）

直し方の見本。架空の苗の注文のサービス。プロジェクトの要件ではない。 / Remedy examples for a fictional plant nursery; not requirements.

## SEC-1 認可
```python
# ❌ 受け取った ID の注文を、誰のものか確かめずに返す
@app.get("/orders/{order_id}")
def get_order(order_id: int, db: Session = Depends(get_db)):
    return db.get(Order, order_id)
# ✅ 呼び出した人の注文の中から探す（無ければ 404。存在を漏らさない）
@app.get("/orders/{order_id}")
def get_order(order_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)):
    order = db.scalar(select(Order).where(Order.id == order_id, Order.customer_id == user.id))
    if order is None:
        raise HTTPException(status_code=404, detail="注文が見つかりません")
    return order
```

## SEC-4 エラーで内部を漏らさない
```python
# ❌ 例外の文字列とトレースバックを応答に入れる
except Exception as e:
    return JSONResponse({"error": str(e), "trace": traceback.format_exc()}, status_code=500)
# ✅ 中はログに、外には決まった文言だけ
except Exception:
    logger.exception("order failed")
    return JSONResponse({"error": "注文を受け付けられませんでした"}, status_code=500)
```

## SEC-6 組み立ての注入
```python
# ❌ f-string で SQL を組み立てる（`' OR '1'='1` で全件が返る）
cur.execute(f"SELECT * FROM seedlings WHERE name LIKE '%{q}%'")
# ✅ パラメータで渡す
cur.execute("SELECT * FROM seedlings WHERE name LIKE %s", (f"%{q}%",))
```
