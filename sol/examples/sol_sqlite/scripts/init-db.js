// Database initialization script using node:sqlite (Node.js 22+)
import { DatabaseSync } from "node:sqlite";

const db = new DatabaseSync("blog.db");

// Create posts table
db.exec(`
  CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author TEXT NOT NULL,
    views INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
`);

// Clear existing data
db.exec("DELETE FROM posts");

// Insert sample posts
const insert = db.prepare(`
  INSERT INTO posts (slug, title, content, author, views)
  VALUES (?, ?, ?, ?, ?)
`);

const posts = [
  {
    slug: "hello-world",
    title: "Hello World",
    content:
      "Welcome to our blog! This is the first post demonstrating ISR with SQLite.",
    author: "Admin",
    views: 1234,
  },
  {
    slug: "moonbit-intro",
    title: "Introduction to MoonBit",
    content:
      "MoonBit is a modern programming language designed for WebAssembly. It combines functional programming concepts with a focus on performance and developer experience.",
    author: "Developer",
    views: 567,
  },
  {
    slug: "isr-explained",
    title: "ISR Explained",
    content:
      "Incremental Static Regeneration (ISR) combines the benefits of static generation with dynamic content updates. Pages are pre-rendered at build time and cached, then regenerated in the background when stale.",
    author: "Architect",
    views: 890,
  },
  {
    slug: "sqlite-node",
    title: "SQLite in Node.js 22",
    content:
      "Node.js 22 introduces a built-in SQLite module (node:sqlite) that provides synchronous database access without external dependencies. Perfect for serverless and edge computing.",
    author: "DevOps",
    views: 456,
  },
  {
    slug: "luna-framework",
    title: "Luna UI Framework",
    content:
      "Luna is an Islands Architecture-based UI framework written in MoonBit. It provides reactive signals, virtual DOM, and SSR capabilities with minimal bundle size.",
    author: "Framework Team",
    views: 789,
  },
];

for (const post of posts) {
  insert.run(post.slug, post.title, post.content, post.author, post.views);
}

console.log(`Initialized database with ${posts.length} posts`);

// Show what was created
const count = db.prepare("SELECT COUNT(*) as count FROM posts").get();
console.log(`Total posts in database: ${count.count}`);

db.close();
