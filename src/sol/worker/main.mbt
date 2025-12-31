// Sol Worker Entry Point
//
// This is the main entry point for worker processes.
// It's forked by the BuilderPool to handle parallel page generation.

///|
fn main {
  @builder_pool.start_worker()
}
