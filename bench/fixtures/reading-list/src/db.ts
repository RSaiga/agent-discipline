import { Database } from 'bun:sqlite'
import type { Book } from './books'

type Row = { id: number; title: string; done: number }
const toBook = (r: Row): Book => ({ id: r.id, title: r.title, done: r.done === 1 })

export const openStore = (path: string) => {
  const db = new Database(path, { create: true })
  db.run('CREATE TABLE IF NOT EXISTS books (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0)')
  return {
    reset: () => db.run('DELETE FROM books'),
    list: (): Book[] => db.query<Row, []>('SELECT id, title, done FROM books ORDER BY id').all().map(toBook),
    add: (title: string): Book => toBook(db.query<Row, [string]>('INSERT INTO books (title) VALUES (?) RETURNING id, title, done').get(title)!),
    markDone: (id: number): Book | null => {
      const r = db.query<Row, [number]>('UPDATE books SET done = 1 WHERE id = ? RETURNING id, title, done').get(id)
      return r ? toBook(r) : null
    },
  }
}
export type Store = ReturnType<typeof openStore>
