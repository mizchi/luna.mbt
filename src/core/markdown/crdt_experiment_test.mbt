///| CRDT実験のテスト

test "LogicalId creation and comparison" {
  let gen = IdGenerator::new(AgentId(1))
  let id1 = gen.next()
  let id2 = gen.next()
  let id3 = gen.next()

  // 順序テスト
  inspect(id1.lt(id2), content="true")
  inspect(id2.lt(id3), content="true")
  inspect(id1.lt(id3), content="true")

  // 同一性テスト
  inspect(id1 == id1, content="true")
  inspect(id1 == id2, content="false")
}

test "LogicalId cross-agent comparison" {
  let gen1 = IdGenerator::new(AgentId(1))
  let gen2 = IdGenerator::new(AgentId(2))

  let id1_0 = gen1.next()  // (agent=1, seq=0)
  let id2_0 = gen2.next()  // (agent=2, seq=0)

  // 同じseqならagentで比較
  inspect(id1_0.lt(id2_0), content="true")

  let id1_1 = gen1.next()  // (agent=1, seq=1)
  // seq=1 > seq=0
  inspect(id2_0.lt(id1_1), content="true")
}

test "CrdtDocument basic operations" {
  let doc = CrdtDocument::new(AgentId(1))

  // 挿入
  let _ = doc.insert("Hello ")
  let _ = doc.insert("World")

  inspect(doc.get_text(), content="Hello World")
  inspect(doc.active_count(), content="2")
  inspect(doc.total_count(), content="2")
}

test "CrdtDocument tombstone" {
  let doc = CrdtDocument::new(AgentId(1))

  let _ = doc.insert("A")
  let _ = doc.insert("B")
  let _ = doc.insert("C")

  inspect(doc.get_text(), content="ABC")

  // 中間を削除
  doc.delete(1)

  inspect(doc.get_text(), content="AC")
  inspect(doc.active_count(), content="2")
  inspect(doc.total_count(), content="3")  // Tombstone残る
}

test "CrdtSpan with cache" {
  let gen = IdGenerator::new(AgentId(1))
  let start = gen.next()
  let end = gen.next()

  let span = CrdtSpan::new(start, end, 0, 10)

  // キャッシュ値を使用可能
  inspect(span.cached_from, content="0")
  inspect(span.cached_to, content="10")

  // 論理IDも保持
  inspect(span.start_id.seq, content="0")
  inspect(span.end_id.seq, content="1")
}

test "TextRun compression simulation" {
  // 5文字を1つのRunで表現（Run-Length Encoding相当）
  let gen = IdGenerator::new(AgentId(1))
  let run = TextRun::{ id: gen.next(), content: "hello", deleted: false }

  // 1エントリで5文字
  inspect(run.content.length(), content="5")
  inspect(run.id.seq, content="0")
}
