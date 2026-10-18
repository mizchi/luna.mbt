import { index, integer, sqliteTable, text } from "void/schema-d1";

export const notes = sqliteTable(
  "notes",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    ownerId: text("owner_id").notNull(),
    title: text("title").notNull(),
  },
  (table) => [index("notes_owner_idx").on(table.ownerId, table.id)],
);
