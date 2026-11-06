import { handler } from './app'
import { openStore } from './db'

const port = Number(process.env.PORT ?? 4310)
const server = Bun.serve({ port, fetch: handler(openStore(process.env.DB_PATH ?? '.data/reading-list.db'), process.env.ALLOW_RESET === '1') })
console.log(`reading-list listening on ${server.port}`)
