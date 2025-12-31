// Luna Testing - Signal Test Utilities
// Signal のリアクティビティをテストするためのユーティリティ

// =============================================================================
// Signal History Tracking
// =============================================================================

///|
/// Signal の値変更履歴を追跡するトラッカー
pub struct SignalTracker[T] {
  values : Array[T]
  cleanup : () -> Unit
}

///|
/// Signal の変更を追跡開始
pub fn[T : Eq] track_signal(sig : @signal.Signal[T]) -> SignalTracker[T] {
  let values : Array[T] = [sig.get()]
  let cleanup = @signal.effect(fn() {
    let v = sig.get()
    // 重複を避けて追加
    if values.length() == 0 || values[values.length() - 1] != v {
      values.push(v)
    }
  })
  { values, cleanup }
}

///|
/// 追跡した値の履歴を取得
pub fn[T] tracker_values(tracker : SignalTracker[T]) -> Array[T] {
  tracker.values
}

///|
/// 追跡を停止
pub fn[T] tracker_stop(tracker : SignalTracker[T]) -> Unit {
  (tracker.cleanup)()
}

///|
/// 最後に記録された値を取得
pub fn[T] tracker_last(tracker : SignalTracker[T]) -> T? {
  if tracker.values.length() > 0 {
    Some(tracker.values[tracker.values.length() - 1])
  } else {
    None
  }
}

///|
/// 値の変更回数を取得
pub fn[T] tracker_count(tracker : SignalTracker[T]) -> Int {
  tracker.values.length()
}

// =============================================================================
// Effect Counter
// =============================================================================

///|
/// Effect の実行回数をカウントするカウンター
pub struct EffectCounter {
  mut count : Int
  cleanup : () -> Unit
}

///|
/// Effect の実行をカウント開始
pub fn count_effect(effect_fn : () -> Unit) -> EffectCounter {
  let counter : Ref[Int] = { val: 0 }
  let cleanup = @signal.effect(fn() {
    effect_fn()
    counter.val = counter.val + 1
  })
  { count: counter.val, cleanup }
}

///|
/// 現在のカウントを取得
pub fn effect_get_count(counter : EffectCounter) -> Int {
  counter.count
}

///|
/// カウントをリセット
pub fn effect_reset(counter : EffectCounter) -> Unit {
  counter.count = 0
}

///|
/// カウントを停止
pub fn effect_stop(counter : EffectCounter) -> Unit {
  (counter.cleanup)()
}

// =============================================================================
// Batch Testing
// =============================================================================

///|
/// Batch 内での Signal 更新をテスト
pub fn test_batch(
  setup : () -> Unit,
  updates : () -> Unit,
  verify : () -> Unit,
) -> Unit {
  setup()
  @signal.batch(updates)
  verify()
}

// =============================================================================
// Signal Assertions
// =============================================================================

///|
/// Signal の現在値を検証
pub fn[T : Eq + Show] assert_signal_value(
  sig : @signal.Signal[T],
  expected : T,
) -> Unit {
  let actual = sig.get()
  if actual != expected {
    abort("Expected signal value \{expected}, but got \{actual}")
  }
}

///|
/// トラッカーの値履歴を検証
pub fn[T : Eq + Show] assert_tracked_values(
  tracker : SignalTracker[T],
  expected : Array[T],
) -> Unit {
  let actual = tracker.values
  if actual.length() != expected.length() {
    abort(
      "Expected \{expected.length()} tracked values, but got \{actual.length()}",
    )
  }
  for i = 0; i < actual.length(); i = i + 1 {
    if actual[i] != expected[i] {
      abort(
        "Tracked value at index \{i}: expected \{expected[i]}, but got \{actual[i]}",
      )
    }
  }
}

///|
/// Effect カウンターの値を検証
pub fn assert_effect_count(counter : EffectCounter, expected : Int) -> Unit {
  let actual = counter.count
  if actual != expected {
    abort("Expected effect to run \{expected} times, but ran \{actual} times")
  }
}
