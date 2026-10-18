import { notes } from "@schema";
import { defineHandler, defineHead, type InferProps } from "void";
import { requireAuth } from "void/auth";
import { db, eq } from "void/db";
import { z } from "zod";

export const loader = defineHandler(async (c) => {
  const user = await requireAuth(c);
  c.header("Cache-Control", "no-store");
  const rows = await db.select().from(notes).where(eq(notes.ownerId, user.id));
  return { name: user.name, initialCount: rows.length, titles: rows.map((row) => row.title) };
});
export type Props = InferProps<typeof loader>;
export const head = defineHead(() => ({ title: "Luna + Void" }));
const noteInput = z.object({ title: z.string().min(1).max(100) });
export const actions = {
  add: defineHandler.withValidator({ body: noteInput })(async (c, { body }) => {
    const user = await requireAuth(c);
    await db.insert(notes).values({ ownerId: user.id, title: body.title });
  }),
  // Void's body validator accepts JSON. Parse native form fields explicitly.
  addForm: defineHandler(async (c) => {
    const user = await requireAuth(c);
    const input = noteInput.safeParse(await c.req.parseBody());
    if (!input.success) return c.text("Title must contain 1–100 characters", 422);
    await db.insert(notes).values({ ownerId: user.id, title: input.data.title });
    return c.redirect(new URL("/", c.req.url).href, 303);
  }),
};
