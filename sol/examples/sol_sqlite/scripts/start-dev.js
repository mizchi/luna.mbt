// Custom dev server start script with SQLite preloading
import { DatabaseSync } from 'node:sqlite';
globalThis.DatabaseSync = DatabaseSync;

// Now import and run the generated server
await import('../.sol/prod/server/main.js');
