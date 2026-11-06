import { titleError } from './books'
import type { Store } from './db'

const json = (body: unknown, status = 200) => Response.json(body, { status })

/** The HTTP API, separated from the server so tests can call it directly. */
export const handler = (store: Store, allowReset = false) => async (req: Request): Promise<Response> => {
  const url = new URL(req.url)
  if (url.pathname === '/health') return json({ ok: true })
  // Only the test stack turns this on, so acceptance scenarios can start from an empty list.
  if (allowReset && url.pathname === '/test/reset' && req.method === 'POST') {
    store.reset()
    return json({ ok: true })
  }
  if (url.pathname === '/books' && req.method === 'GET') return json(store.list())
  if (url.pathname === '/books' && req.method === 'POST') {
    const { title } = await req.json().catch(() => ({}))
    const error = titleError(title)
    if (error) return json({ error }, 400)
    return json(store.add(title.trim()), 201)
  }
  const done = url.pathname.match(/^\/books\/(\d+)\/done$/)
  if (done && req.method === 'POST') {
    const book = store.markDone(Number(done[1]))
    return book ? json(book) : json({ error: '本が見つかりません' }, 404)
  }
  return json({ error: 'not found' }, 404)
}
