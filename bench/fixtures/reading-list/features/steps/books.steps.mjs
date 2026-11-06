import assert from 'node:assert/strict'
import { Before, Given, Then, When } from '@cucumber/cucumber'

const base = () => `http://localhost:${process.env.PORT ?? 4310}`
const call = async (method, path, body) => {
  const res = await fetch(base() + path, { method, body: body === undefined ? undefined : JSON.stringify(body) })
  return { status: res.status, body: await res.json() }
}
const books = async () => (await call('GET', '/books')).body
const idOf = async (title) => (await books()).find((b) => b.title === title).id

// Every scenario starts from an empty list; the stack keeps running between scenarios.
Before(async () => {
  await call('POST', '/test/reset')
})

When('本 {string} を足す', async function (title) {
  this.last = await call('POST', '/books', { title })
})
Given('本 {string} と {string} がある', async (a, b) => {
  await call('POST', '/books', { title: a })
  await call('POST', '/books', { title: b })
})
When('{string} に読み終えた印を付ける', async (title) => {
  await call('POST', `/books/${await idOf(title)}/done`)
})
Then('一覧に次の本が並ぶ', async (table) => {
  const want = table.hashes().map((r) => ({ title: r['タイトル'], status: r['状態'] }))
  const got = (await books()).map((b) => ({ title: b.title, status: b.done ? '読了' : '未読' }))
  assert.deepEqual(got, want)
})
Then('{string} と断られる', function (message) {
  assert.equal(this.last.status, 400)
  assert.equal(this.last.body.error, message)
})
Then('一覧は空のまま', async () => {
  assert.deepEqual(await books(), [])
})
