import { useState, useEffect, useRef, useCallback } from 'react'

// =============================================================================
// Configuration
// =============================================================================

const GRID_SIZE = 100
const TARGET_FPS = 60
const ENEMY_SPAWN_INTERVAL = 2000
const PLAYER_BULLET_INTERVAL = 100
const ENEMY_BULLET_INTERVAL = 1000
const BULLET_SPEED = 0.5
const ENEMY_SPEED = 0.05
const MAX_ENEMIES = 50
const PLAYER_SPEED = 1.0

// =============================================================================
// Types
// =============================================================================

interface Vec2 {
  x: number
  y: number
}

interface Bullet {
  pos: Vec2
  vel: Vec2
  isPlayerBullet: boolean
  id: number
}

interface Enemy {
  pos: Vec2
  id: number
  lastShot: number
}

interface GameState {
  playerPos: Vec2
  playerAngle: number
  bullets: Bullet[]
  enemies: Enemy[]
  score: number
  nextBulletId: number
  nextEnemyId: number
  lastPlayerShot: number
  lastEnemySpawn: number
  frameCount: number
  fps: number
  lastFpsTime: number
}

// =============================================================================
// Helpers
// =============================================================================

const distance = (a: Vec2, b: Vec2): number => {
  const dx = a.x - b.x
  const dy = a.y - b.y
  return Math.sqrt(dx * dx + dy * dy)
}

const normalize = (v: Vec2): Vec2 => {
  const len = Math.sqrt(v.x * v.x + v.y * v.y)
  return len > 0 ? { x: v.x / len, y: v.y / len } : { x: 0, y: 0 }
}

const clamp = (v: number, min: number, max: number): number =>
  v < min ? min : v > max ? max : v

// =============================================================================
// Game Logic
// =============================================================================

const createInitialState = (): GameState => {
  const now = performance.now()
  return {
    playerPos: { x: 50, y: 50 },
    playerAngle: 0,
    bullets: [],
    enemies: [],
    score: 0,
    nextBulletId: 0,
    nextEnemyId: 0,
    lastPlayerShot: now,
    lastEnemySpawn: now,
    frameCount: 0,
    fps: 0,
    lastFpsTime: now,
  }
}

const spawnEnemy = (state: GameState, now: number): GameState => {
  if (state.enemies.length >= MAX_ENEMIES) return state
  const edge = Math.floor(Math.random() * 4)
  let pos: Vec2
  switch (edge) {
    case 0: pos = { x: Math.random() * GRID_SIZE, y: 0 }; break
    case 1: pos = { x: GRID_SIZE - 1, y: Math.random() * GRID_SIZE }; break
    case 2: pos = { x: Math.random() * GRID_SIZE, y: GRID_SIZE - 1 }; break
    default: pos = { x: 0, y: Math.random() * GRID_SIZE }
  }
  return {
    ...state,
    enemies: [...state.enemies, { pos, id: state.nextEnemyId, lastShot: now }],
    nextEnemyId: state.nextEnemyId + 1,
  }
}

const spawnPlayerBullet = (state: GameState, now: number): GameState => {
  const dir = { x: Math.cos(state.playerAngle), y: Math.sin(state.playerAngle) }
  const bullet: Bullet = {
    pos: { ...state.playerPos },
    vel: { x: dir.x * BULLET_SPEED, y: dir.y * BULLET_SPEED },
    isPlayerBullet: true,
    id: state.nextBulletId,
  }
  return {
    ...state,
    bullets: [...state.bullets, bullet],
    nextBulletId: state.nextBulletId + 1,
    lastPlayerShot: now,
    playerAngle: state.playerAngle + Math.PI / 8,
  }
}

const spawnEnemyBullet = (state: GameState, enemy: Enemy, now: number): { state: GameState; enemy: Enemy } => {
  const dir = normalize({ x: state.playerPos.x - enemy.pos.x, y: state.playerPos.y - enemy.pos.y })
  const bullet: Bullet = {
    pos: { ...enemy.pos },
    vel: { x: dir.x * BULLET_SPEED * 0.7, y: dir.y * BULLET_SPEED * 0.7 },
    isPlayerBullet: false,
    id: state.nextBulletId,
  }
  return {
    state: { ...state, bullets: [...state.bullets, bullet], nextBulletId: state.nextBulletId + 1 },
    enemy: { ...enemy, lastShot: now },
  }
}

const updateBullets = (state: GameState): GameState => {
  const newBullets = state.bullets
    .map(b => ({ ...b, pos: { x: b.pos.x + b.vel.x, y: b.pos.y + b.vel.y } }))
    .filter(b => b.pos.x >= 0 && b.pos.x < GRID_SIZE && b.pos.y >= 0 && b.pos.y < GRID_SIZE)
  return { ...state, bullets: newBullets }
}

const updateEnemies = (state: GameState): GameState => {
  const newEnemies = state.enemies.map(e => {
    const dir = normalize({ x: state.playerPos.x - e.pos.x, y: state.playerPos.y - e.pos.y })
    return { ...e, pos: { x: e.pos.x + dir.x * ENEMY_SPEED, y: e.pos.y + dir.y * ENEMY_SPEED } }
  })
  return { ...state, enemies: newEnemies }
}

const movePlayer = (state: GameState, dx: number, dy: number): GameState => ({
  ...state,
  playerPos: {
    x: clamp(state.playerPos.x + dx, 0, GRID_SIZE - 1),
    y: clamp(state.playerPos.y + dy, 0, GRID_SIZE - 1),
  },
})

const checkCollisions = (state: GameState): GameState => {
  const bulletsToRemove = new Set<number>()
  const enemiesToRemove = new Set<number>()
  let score = state.score

  for (const b of state.bullets) {
    if (b.isPlayerBullet) {
      for (const e of state.enemies) {
        if (distance(b.pos, e.pos) < 1.5) {
          bulletsToRemove.add(b.id)
          enemiesToRemove.add(e.id)
          score += 10
        }
      }
    }
  }

  return {
    ...state,
    bullets: state.bullets.filter(b => !bulletsToRemove.has(b.id)),
    enemies: state.enemies.filter(e => !enemiesToRemove.has(e.id)),
    score,
  }
}

const gameTick = (state: GameState, keyState: KeyState): GameState => {
  const now = performance.now()
  let newFrameCount: number, newFps: number, newFpsTime: number

  if (now - state.lastFpsTime >= 1000) {
    newFrameCount = 0
    newFps = state.frameCount
    newFpsTime = now
  } else {
    newFrameCount = state.frameCount + 1
    newFps = state.fps
    newFpsTime = state.lastFpsTime
  }

  let s: GameState = { ...state, frameCount: newFrameCount, fps: newFps, lastFpsTime: newFpsTime }

  // Apply keyboard input
  let dx = 0, dy = 0
  if (keyState.up) dy -= PLAYER_SPEED
  if (keyState.down) dy += PLAYER_SPEED
  if (keyState.left) dx -= PLAYER_SPEED
  if (keyState.right) dx += PLAYER_SPEED
  if (dx !== 0 || dy !== 0) {
    s = movePlayer(s, dx, dy)
  }

  if (now - s.lastEnemySpawn >= ENEMY_SPAWN_INTERVAL) {
    s = spawnEnemy(s, now)
    s = { ...s, lastEnemySpawn: now }
  }

  if (now - s.lastPlayerShot >= PLAYER_BULLET_INTERVAL) {
    s = spawnPlayerBullet(s, now)
  }

  const updatedEnemies: Enemy[] = []
  for (const e of s.enemies) {
    if (now - e.lastShot >= ENEMY_BULLET_INTERVAL) {
      const result = spawnEnemyBullet(s, e, now)
      s = result.state
      updatedEnemies.push(result.enemy)
    } else {
      updatedEnemies.push(e)
    }
  }
  s = { ...s, enemies: updatedEnemies }

  s = updateBullets(s)
  s = updateEnemies(s)
  s = checkCollisions(s)

  return s
}

// =============================================================================
// Rendering
// =============================================================================

interface KeyState {
  up: boolean
  down: boolean
  left: boolean
  right: boolean
}

const getCellType = (x: number, y: number, state: GameState): number => {
  const px = state.playerPos.x | 0
  const py = state.playerPos.y | 0
  if (x === px && y === py) return 1

  for (const b of state.bullets) {
    if ((b.pos.x | 0) === x && (b.pos.y | 0) === y) {
      return b.isPlayerBullet ? 2 : 3
    }
  }

  for (const e of state.enemies) {
    if ((e.pos.x | 0) === x && (e.pos.y | 0) === y) return 4
  }

  return 0
}

const indices = Array.from({ length: GRID_SIZE * GRID_SIZE }, (_, i) => i)

function App() {
  const [state, setState] = useState<GameState>(createInitialState)
  const [running, setRunning] = useState(true)
  const keyStateRef = useRef<KeyState>({ up: false, down: false, left: false, right: false })
  const cellRefs = useRef<(HTMLDivElement | null)[]>([])
  const prevCellTypes = useRef<number[]>(new Array(GRID_SIZE * GRID_SIZE).fill(0))

  // Keyboard input
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      let isArrow = false
      switch (e.key) {
        case 'ArrowUp': keyStateRef.current.up = true; isArrow = true; break
        case 'ArrowDown': keyStateRef.current.down = true; isArrow = true; break
        case 'ArrowLeft': keyStateRef.current.left = true; isArrow = true; break
        case 'ArrowRight': keyStateRef.current.right = true; isArrow = true; break
      }
      if (isArrow) {
        e.preventDefault()
        // Immediate response
        const ks = keyStateRef.current
        let dx = 0, dy = 0
        if (ks.up) dy -= PLAYER_SPEED
        if (ks.down) dy += PLAYER_SPEED
        if (ks.left) dx -= PLAYER_SPEED
        if (ks.right) dx += PLAYER_SPEED
        if (dx !== 0 || dy !== 0) {
          setState(s => movePlayer(s, dx, dy))
        }
      }
    }

    const handleKeyUp = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'ArrowUp': keyStateRef.current.up = false; break
        case 'ArrowDown': keyStateRef.current.down = false; break
        case 'ArrowLeft': keyStateRef.current.left = false; break
        case 'ArrowRight': keyStateRef.current.right = false; break
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    window.addEventListener('keyup', handleKeyUp)
    return () => {
      window.removeEventListener('keydown', handleKeyDown)
      window.removeEventListener('keyup', handleKeyUp)
    }
  }, [])

  // Game loop
  useEffect(() => {
    const interval = setInterval(() => {
      if (running) {
        setState(s => gameTick(s, keyStateRef.current))
      }
    }, 1000 / TARGET_FPS)
    return () => clearInterval(interval)
  }, [running])

  // Dirty tracking for grid updates
  useEffect(() => {
    for (let i = 0; i < cellRefs.current.length; i++) {
      const x = i % GRID_SIZE
      const y = Math.floor(i / GRID_SIZE)
      const cellType = getCellType(x, y, state)
      if (cellType !== prevCellTypes.current[i]) {
        prevCellTypes.current[i] = cellType
        const el = cellRefs.current[i]
        if (el) {
          el.className = `cell c${cellType}`
        }
      }
    }
  }, [state])

  const handleReset = useCallback(() => {
    setState(createInitialState())
  }, [])

  return (
    <div className="container">
      <h1>React Benchmark Game</h1>
      <div className="stats">
        <span>FPS: {state.fps}</span>
        <span>Score: {state.score}</span>
        <span>Enemies: {state.enemies.length}</span>
        <span>Bullets: {state.bullets.length}</span>
      </div>
      <div className="controls">
        <button onClick={() => setRunning(r => !r)}>
          {running ? 'Pause' : 'Run'}
        </button>
        <button onClick={handleReset}>Reset</button>
      </div>
      <div className="grid-wrapper">
        <div className="grid">
          {indices.map(i => (
            <div
              key={i}
              ref={el => { cellRefs.current[i] = el }}
              className="cell c0"
            />
          ))}
        </div>
      </div>
      <div className="legend">
        Arrow keys to move | White=Player | Green=Player Bullets | Yellow=Enemy Bullets | Red=Enemies
      </div>
    </div>
  )
}

export default App
