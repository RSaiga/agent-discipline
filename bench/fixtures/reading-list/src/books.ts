/** A book on the reading list. */
export type Book = { id: number; title: string; done: boolean }

export const TITLE_MAX = 100

/** Returns the error message for an invalid title, or null when it is acceptable. */
export const titleError = (title: unknown): string | null => {
  if (typeof title !== 'string' || title.trim() === '') return 'タイトルは必須です'
  if ([...title.trim()].length > TITLE_MAX) return `タイトルは${TITLE_MAX}文字以内にしてください`
  return null
}
