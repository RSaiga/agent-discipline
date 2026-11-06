import { describe, expect, test } from 'bun:test'
import { handler } from '../src/app'
import { titleError } from '../src/books'
import { openStore } from '../src/db'

const api = () => handler(openStore(':memory:'))
const post = (path: string, body?: unknown) =>
  new Request(`http://test${path}`, { method: 'POST', body: body === undefined ? undefined : JSON.stringify(body) })

describe('titleError', () => {
  test('空のタイトルは必須のエラーになる', () => {
    // Given / When / Then
    expect(titleError('  ')).toBe('タイトルは必須です')
  })
  test('100 文字を超えると長さのエラーになる', () => {
    expect(titleError('あ'.repeat(101))).toBe('タイトルは100文字以内にしてください')
    expect(titleError('あ'.repeat(100))).toBeNull()
  })
})

describe('POST /books', () => {
  test('前後の空白を除いたタイトルで本を足し、未読で返す', async () => {
    // Given
    const app = api()
    // When
    const res = await app(post('/books', { title: '  坊っちゃん ' }))
    // Then
    expect(res.status).toBe(201)
    expect(await res.json()).toEqual({ id: 1, title: '坊っちゃん', done: false })
  })
})

describe('POST /books/:id/done', () => {
  test('無い本に印を付けると 404', async () => {
    const res = await api()(post('/books/9/done'))
    expect(res.status).toBe(404)
  })
})
