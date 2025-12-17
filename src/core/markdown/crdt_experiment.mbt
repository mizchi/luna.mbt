///| CRDT初期検証: LogicalId導入のオーバーヘッド測定

// =============================================================================
// 実験用型定義
// =============================================================================

///| Agent識別子 (簡易版: Int)
pub(all) struct AgentId(Int) derive(Eq, Show)

///| 論理ID: (agent, seq) ペア
#valtype
pub(all) struct LogicalId {
  agent : AgentId
  seq : Int
} derive(Eq, Show)

///| LogicalId生成器
pub(all) struct IdGenerator {
  agent : AgentId
  mut next_seq : Int
}

pub fn IdGenerator::new(agent : AgentId) -> IdGenerator {
  { agent, next_seq: 0 }
}

pub fn IdGenerator::next(self : IdGenerator) -> LogicalId {
  let id = { agent: self.agent, seq: self.next_seq }
  self.next_seq += 1
  id
}

///| CRDT対応Span (キャッシュ付き)
pub(all) struct CrdtSpan {
  start_id : LogicalId
  end_id : LogicalId
  // 絶対位置キャッシュ（高速アクセス用）
  cached_from : Int
  cached_to : Int
}

pub fn CrdtSpan::new(
  start_id : LogicalId,
  end_id : LogicalId,
  from : Int,
  to : Int
) -> CrdtSpan {
  { start_id, end_id, cached_from: from, cached_to: to }
}

///| TextRun: 連続テキストの圧縮表現
pub(all) struct TextRun {
  id : LogicalId       // 開始ID
  content : String     // テキスト内容
  deleted : Bool       // Tombstone
}

///| 実験用ドキュメント構造
pub(all) struct CrdtDocument {
  runs : Array[TextRun]
  gen : IdGenerator
}

pub fn CrdtDocument::new(agent : AgentId) -> CrdtDocument {
  { runs: [], gen: IdGenerator::new(agent) }
}

///| テキスト挿入
pub fn CrdtDocument::insert(self : CrdtDocument, text : String) -> LogicalId {
  let id = self.gen.next()
  self.runs.push({ id, content: text, deleted: false })
  id
}

///| 削除（Tombstone化）
pub fn CrdtDocument::delete(self : CrdtDocument, idx : Int) -> Unit {
  if idx < self.runs.length() {
    let run = self.runs[idx]
    self.runs[idx] = { ..run, deleted: true }
  }
}

///| アクティブなテキストを取得
pub fn CrdtDocument::get_text(self : CrdtDocument) -> String {
  let buf = StringBuilder::new()
  for run in self.runs {
    if not(run.deleted) {
      buf.write_string(run.content)
    }
  }
  buf.to_string()
}

///| アクティブなRun数
pub fn CrdtDocument::active_count(self : CrdtDocument) -> Int {
  let mut count = 0
  for run in self.runs {
    if not(run.deleted) {
      count += 1
    }
  }
  count
}

///| 全Run数（Tombstone含む）
pub fn CrdtDocument::total_count(self : CrdtDocument) -> Int {
  self.runs.length()
}

// =============================================================================
// LogicalId 比較関数 (CRDT merge用)
// =============================================================================

///| LogicalId の順序比較 (Lamport順序)
pub fn LogicalId::compare(self : LogicalId, other : LogicalId) -> Int {
  // まずseqで比較、同じならagentで比較
  if self.seq != other.seq {
    self.seq - other.seq
  } else {
    let AgentId(a1) = self.agent
    let AgentId(a2) = other.agent
    a1 - a2
  }
}

pub fn LogicalId::lt(self : LogicalId, other : LogicalId) -> Bool {
  self.compare(other) < 0
}

pub fn LogicalId::le(self : LogicalId, other : LogicalId) -> Bool {
  self.compare(other) <= 0
}
