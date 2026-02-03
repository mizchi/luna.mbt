//

///|
/// Benchmark Game - Heavy DOM rendering stress test for Luna UI

///|
using @element {
  div,
  span,
  h1,
  button,
  text,
  text_dyn,
  for_each,
  render,
  events,
  type DomNode,
  type DomElement,
}

// =============================================================================
// Configuration
// =============================================================================

///|
const GRID_SIZE : Int = 100

///|
const TARGET_FPS : Int = 60

///|
const ENEMY_SPAWN_INTERVAL : Int = 2000

///|
const PLAYER_BULLET_INTERVAL : Int = 100

///|
const ENEMY_BULLET_INTERVAL : Int = 1000

///|
const BULLET_SPEED : Double = 0.5

///|
const ENEMY_SPEED : Double = 0.05

///|
const MAX_ENEMIES : Int = 50

///|
const PLAYER_SPEED : Double = 1.0

///|
const PI : Double = 3.14159265358979323846

// =============================================================================
// Types
// =============================================================================

///|
priv struct Vec2 {
  x : Double
  y : Double
}

///|
fn Vec2::new(x : Double, y : Double) -> Vec2 {
  { x, y }
}

///|
fn Vec2::distance(self : Vec2, other : Vec2) -> Double {
  let dx = self.x - other.x
  let dy = self.y - other.y
  (dx * dx + dy * dy).sqrt()
}

///|
fn Vec2::normalize(self : Vec2) -> Vec2 {
  let len = (self.x * self.x + self.y * self.y).sqrt()
  if len > 0.0 {
    Vec2::new(self.x / len, self.y / len)
  } else {
    Vec2::new(0.0, 0.0)
  }
}

///|
priv struct Bullet {
  pos : Vec2
  vel : Vec2
  is_player_bullet : Bool
  id : Int
}

///|
priv struct Enemy {
  pos : Vec2
  id : Int
  last_shot : Int
}

///|
priv struct GameState {
  player_pos : Vec2
  player_angle : Double
  bullets : Array[Bullet]
  enemies : Array[Enemy]
  score : Int
  next_bullet_id : Int
  next_enemy_id : Int
  last_player_shot : Int
  last_enemy_spawn : Int
  frame_count : Int
  fps : Int
  last_fps_time : Int
}

// =============================================================================
// JS Helpers
// =============================================================================

///|
fn console_log(msg : String) -> Unit {
  @global.global_this()["console"]._call("log", [@js.any(msg)]) |> ignore
}

///|
fn performance_now() -> Int {
  let perf : @js.Any = @global.global_this()["performance"]
  let now : Double = perf._call("now", []).cast()
  now.to_int()
}

///|
extern "js" fn math_sin(x : Double) -> Double =
  #| (x) => Math.sin(x)

///|
extern "js" fn math_cos(x : Double) -> Double =
  #| (x) => Math.cos(x)

///|
extern "js" fn math_random() -> Double =
  #| () => Math.random()

///|
extern "js" fn _math_floor(x : Double) -> Int =
  #| (x) => Math.floor(x)

///|
extern "js" fn to_int_fast(x : Double) -> Int =
  #| (x) => x | 0

// =============================================================================
// Game Logic
// =============================================================================

///|
fn create_initial_state() -> GameState {
  let now = performance_now()
  {
    player_pos: Vec2::new(50.0, 50.0),
    player_angle: 0.0,
    bullets: [],
    enemies: [],
    score: 0,
    next_bullet_id: 0,
    next_enemy_id: 0,
    last_player_shot: now,
    last_enemy_spawn: now,
    frame_count: 0,
    fps: 0,
    last_fps_time: now,
  }
}

///|
fn spawn_enemy(state : GameState, now : Int) -> GameState {
  if state.enemies.length() >= MAX_ENEMIES {
    return state
  }
  let edge = (math_random() * 4.0).to_int()
  let pos = match edge {
    0 => Vec2::new(math_random() * GRID_SIZE.to_double(), 0.0)
    1 =>
      Vec2::new(
        GRID_SIZE.to_double() - 1.0,
        math_random() * GRID_SIZE.to_double(),
      )
    2 =>
      Vec2::new(
        math_random() * GRID_SIZE.to_double(),
        GRID_SIZE.to_double() - 1.0,
      )
    _ => Vec2::new(0.0, math_random() * GRID_SIZE.to_double())
  }
  let new_enemies = state.enemies.copy()
  new_enemies.push({ pos, id: state.next_enemy_id, last_shot: now })
  { ..state, enemies: new_enemies, next_enemy_id: state.next_enemy_id + 1 }
}

///|
fn spawn_player_bullet(state : GameState, now : Int) -> GameState {
  let dir = Vec2::new(
    math_cos(state.player_angle),
    math_sin(state.player_angle),
  )
  let bullet : Bullet = {
    pos: Vec2::new(state.player_pos.x, state.player_pos.y),
    vel: Vec2::new(dir.x * BULLET_SPEED, dir.y * BULLET_SPEED),
    is_player_bullet: true,
    id: state.next_bullet_id,
  }
  let new_bullets = state.bullets.copy()
  new_bullets.push(bullet)
  {
    ..state,
    bullets: new_bullets,
    next_bullet_id: state.next_bullet_id + 1,
    last_player_shot: now,
    player_angle: state.player_angle + PI / 8.0,
  }
}

///|
fn spawn_enemy_bullet(
  state : GameState,
  enemy : Enemy,
  now : Int,
) -> (GameState, Enemy) {
  let dir = Vec2::new(
    state.player_pos.x - enemy.pos.x,
    state.player_pos.y - enemy.pos.y,
  ).normalize()
  let bullet : Bullet = {
    pos: Vec2::new(enemy.pos.x, enemy.pos.y),
    vel: Vec2::new(dir.x * BULLET_SPEED * 0.7, dir.y * BULLET_SPEED * 0.7),
    is_player_bullet: false,
    id: state.next_bullet_id,
  }
  let new_bullets = state.bullets.copy()
  new_bullets.push(bullet)
  let new_state = {
    ..state,
    bullets: new_bullets,
    next_bullet_id: state.next_bullet_id + 1,
  }
  let new_enemy = { ..enemy, last_shot: now }
  (new_state, new_enemy)
}

///|
fn update_bullets(state : GameState) -> GameState {
  let new_bullets : Array[Bullet] = []
  for b in state.bullets {
    let new_pos = Vec2::new(b.pos.x + b.vel.x, b.pos.y + b.vel.y)
    if new_pos.x >= 0.0 &&
      new_pos.x < GRID_SIZE.to_double() &&
      new_pos.y >= 0.0 &&
      new_pos.y < GRID_SIZE.to_double() {
      new_bullets.push({ ..b, pos: new_pos })
    }
  }
  { ..state, bullets: new_bullets }
}

///|
fn update_enemies(state : GameState) -> GameState {
  let new_enemies : Array[Enemy] = []
  for e in state.enemies {
    let dir = Vec2::new(
      state.player_pos.x - e.pos.x,
      state.player_pos.y - e.pos.y,
    ).normalize()
    let new_pos = Vec2::new(
      e.pos.x + dir.x * ENEMY_SPEED,
      e.pos.y + dir.y * ENEMY_SPEED,
    )
    new_enemies.push({ ..e, pos: new_pos })
  }
  { ..state, enemies: new_enemies }
}

///|
fn clamp(v : Double, min : Double, max : Double) -> Double {
  if v < min {
    min
  } else if v > max {
    max
  } else {
    v
  }
}

///|
fn move_player(state : GameState, dx : Double, dy : Double) -> GameState {
  let new_x = clamp(state.player_pos.x + dx, 0.0, GRID_SIZE.to_double() - 1.0)
  let new_y = clamp(state.player_pos.y + dy, 0.0, GRID_SIZE.to_double() - 1.0)
  { ..state, player_pos: Vec2::new(new_x, new_y) }
}

///|
fn check_collisions(state : GameState) -> GameState {
  let new_bullets : Array[Bullet] = state.bullets.copy()
  let new_enemies : Array[Enemy] = state.enemies.copy()
  let mut score = state.score
  let bullets_to_remove : Array[Int] = []
  let enemies_to_remove : Array[Int] = []
  for b in new_bullets {
    if b.is_player_bullet {
      for e in new_enemies {
        if b.pos.distance(e.pos) < 1.5 {
          bullets_to_remove.push(b.id)
          enemies_to_remove.push(e.id)
          score = score + 10
        }
      }
    }
  }
  let filtered_bullets : Array[Bullet] = []
  for b in new_bullets {
    let mut remove = false
    for id in bullets_to_remove {
      if b.id == id {
        remove = true
        break
      }
    }
    if not(remove) {
      filtered_bullets.push(b)
    }
  }
  let filtered_enemies : Array[Enemy] = []
  for e in new_enemies {
    let mut remove = false
    for id in enemies_to_remove {
      if e.id == id {
        remove = true
        break
      }
    }
    if not(remove) {
      filtered_enemies.push(e)
    }
  }
  { ..state, bullets: filtered_bullets, enemies: filtered_enemies, score }
}

///|
fn game_tick(state : GameState) -> GameState {
  let now = performance_now()
  let (new_frame_count, new_fps, new_fps_time) = if now - state.last_fps_time >=
    1000 {
    (0, state.frame_count, now)
  } else {
    (state.frame_count + 1, state.fps, state.last_fps_time)
  }
  let mut s = {
    ..state,
    frame_count: new_frame_count,
    fps: new_fps,
    last_fps_time: new_fps_time,
  }

  // Apply keyboard input
  s = apply_input(s)
  if now - s.last_enemy_spawn >= ENEMY_SPAWN_INTERVAL {
    s = spawn_enemy(s, now)
    s = { ..s, last_enemy_spawn: now }
  }
  if now - s.last_player_shot >= PLAYER_BULLET_INTERVAL {
    s = spawn_player_bullet(s, now)
  }
  let updated_enemies : Array[Enemy] = []
  for e in s.enemies {
    if now - e.last_shot >= ENEMY_BULLET_INTERVAL {
      let (ns, ne) = spawn_enemy_bullet(s, e, now)
      s = ns
      updated_enemies.push(ne)
    } else {
      updated_enemies.push(e)
    }
  }
  s = { ..s, enemies: updated_enemies }
  s = update_bullets(s)
  s = update_enemies(s)
  s = check_collisions(s)
  s
}

// =============================================================================
// Rendering
// =============================================================================

// Cell types: 0=empty, 1=player, 2=player_bullet, 3=enemy_bullet, 4=enemy

///|
fn get_cell_type(x : Int, y : Int, state : GameState) -> Int {
  let px = to_int_fast(state.player_pos.x)
  let py = to_int_fast(state.player_pos.y)
  if x == px && y == py {
    return 1
  }
  for b in state.bullets {
    if to_int_fast(b.pos.x) == x && to_int_fast(b.pos.y) == y {
      return if b.is_player_bullet { 2 } else { 3 }
    }
  }
  for e in state.enemies {
    if to_int_fast(e.pos.x) == x && to_int_fast(e.pos.y) == y {
      return 4
    }
  }
  0
}

///|
fn cell_class(cell_type : Int) -> String {
  "cell c" + cell_type.to_string()
}

///|
fn make_indices() -> Array[Int] {
  let arr : Array[Int] = []
  let total = GRID_SIZE * GRID_SIZE
  for i in 0..<total {
    arr.push(i)
  }
  arr
}

// Store cell elements and previous state for dirty tracking

///|
let cell_elements : Array[@dom.Element] = []

///|
let prev_cell_types : Array[Int] = []

///|
fn init_prev_cell_types() -> Unit {
  let total = GRID_SIZE * GRID_SIZE
  for i in 0..<total {
    prev_cell_types.push(0)
  }
}

///|
fn render_grid(state_sig : @resource.Signal[GameState]) -> DomNode {
  let indices = make_indices()
  init_prev_cell_types()
  // Single effect with dirty tracking - only update changed cells
  let _ = @resource.effect(fn() {
    let state = state_sig.get()
    for i in 0..<cell_elements.length() {
      let x = i % GRID_SIZE
      let y = i / GRID_SIZE
      let cell_type = get_cell_type(x, y, state)
      // Only update DOM if cell type changed
      if cell_type != prev_cell_types[i] {
        prev_cell_types[i] = cell_type
        cell_elements[i].setClassName(cell_class(cell_type))
      }
    }
  })
  div(class="grid", [
    for_each(fn() { indices }, fn(_, _) {
      div(class="cell c0", ref_=el => cell_elements.push(el), [])
    }),
  ])
}

///|
fn render_stats(state_sig : @resource.Signal[GameState]) -> DomNode {
  div(class="stats", [
    span([text_dyn(fn() { "FPS: " + state_sig.get().fps.to_string() })]),
    span([text_dyn(fn() { "Score: " + state_sig.get().score.to_string() })]),
    span([
      text_dyn(fn() {
        "Enemies: " + state_sig.get().enemies.length().to_string()
      }),
    ]),
    span([
      text_dyn(fn() {
        "Bullets: " + state_sig.get().bullets.length().to_string()
      }),
    ]),
  ])
}

///|
fn render_controls(
  running_sig : @resource.Signal[Bool],
  on_reset : () -> Unit,
) -> DomNode {
  div(class="controls", [
    button(on=events().click(_ => running_sig.update(r => not(r))), [
      text_dyn(fn() { if running_sig.get() { "Pause" } else { "Run" } }),
    ]),
    button(on=events().click(_ => on_reset()), [text("Reset")]),
  ])
}

// =============================================================================
// Input State
// =============================================================================

///|
priv struct KeyState {
  mut up : Bool
  mut down : Bool
  mut left : Bool
  mut right : Bool
}

///|
let key_state : KeyState = { up: false, down: false, left: false, right: false }

///|
fn setup_keyboard(state_sig : @resource.Signal[GameState]) -> Unit {
  let win = @dom.window()
  win
  .as_event_target()
  .addEventListener("keydown", fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let is_arrow = match key {
      "ArrowUp" => {
        key_state.up = true
        true
      }
      "ArrowDown" => {
        key_state.down = true
        true
      }
      "ArrowLeft" => {
        key_state.left = true
        true
      }
      "ArrowRight" => {
        key_state.right = true
        true
      }
      _ => false
    }
    // Apply on every keydown (including repeat)
    if is_arrow {
      state_sig.update(apply_input)
      e._call("preventDefault", []) |> ignore
    }
  })
  win
  .as_event_target()
  .addEventListener("keyup", fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    match key {
      "ArrowUp" => key_state.up = false
      "ArrowDown" => key_state.down = false
      "ArrowLeft" => key_state.left = false
      "ArrowRight" => key_state.right = false
      _ => ()
    }
  })
}

///|
fn apply_input(state : GameState) -> GameState {
  let mut dx = 0.0
  let mut dy = 0.0
  if key_state.up {
    dy = dy - PLAYER_SPEED
  }
  if key_state.down {
    dy = dy + PLAYER_SPEED
  }
  if key_state.left {
    dx = dx - PLAYER_SPEED
  }
  if key_state.right {
    dx = dx + PLAYER_SPEED
  }
  if dx != 0.0 || dy != 0.0 {
    move_player(state, dx, dy)
  } else {
    state
  }
}

///|
fn main {
  console_log("Luna Benchmark Game Starting...")
  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let state_sig = @resource.signal(create_initial_state())
      let running_sig = @resource.signal(true)
      setup_keyboard(state_sig)
      let _ = @global.setInterval(
        fn() { if running_sig.get() { state_sig.update(game_tick) } },
        1000 / TARGET_FPS,
      )
      let app = div(class="container", [
        h1([text("Luna Benchmark Game")]),
        render_stats(state_sig),
        render_controls(running_sig, fn() {
          state_sig.set(create_initial_state())
        }),
        div(class="grid-wrapper", [render_grid(state_sig)]),
        div(class="legend", [
          text(
            "Arrow keys to move | White=Player | Green=Player Bullets | Yellow=Enemy Bullets | Red=Enemies",
          ),
        ]),
      ])
      render(el |> DomElement::from_dom, app)
      console_log("Game initialized!")
    }
    None => console_log("ERROR: Could not find #app")
  }
}
