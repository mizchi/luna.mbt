// Preload node:sqlite and make it available globally
import { DatabaseSync } from "node:sqlite";
globalThis.DatabaseSync = DatabaseSync;
