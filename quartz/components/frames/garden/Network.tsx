// A faint, deterministic hypha network drawn behind the home header.
// Seeded so every build produces the same drawing.
const W = 896
const H = 300
const COLS = 8
const ROWS = 4

function mulberry32(seed: number) {
  let a = seed
  return () => {
    a |= 0
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

type Pt = { x: number; y: number }

function buildNetwork(): { nodes: Pt[]; edges: [Pt, Pt][] } {
  const rand = mulberry32(7)
  const cw = W / COLS
  const ch = H / ROWS
  const nodes: Pt[] = []
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      nodes.push({
        x: Math.round((c + 0.15 + rand() * 0.7) * cw * 10) / 10,
        y: Math.round((r + 0.15 + rand() * 0.7) * ch * 10) / 10,
      })
    }
  }
  const seen = new Set<string>()
  const edges: [Pt, Pt][] = []
  nodes.forEach((n, i) => {
    const nearest = nodes
      .map((m, j) => ({ j, d: (m.x - n.x) ** 2 + (m.y - n.y) ** 2 }))
      .filter((o) => o.j !== i)
      .sort((p, q) => p.d - q.d)
      .slice(0, 2)
    for (const { j } of nearest) {
      const key = i < j ? `${i}-${j}` : `${j}-${i}`
      if (!seen.has(key)) {
        seen.add(key)
        edges.push([n, nodes[j]])
      }
    }
  })
  return { nodes, edges }
}

export function Network() {
  const { nodes, edges } = buildNetwork()
  return (
    <svg
      data-role="network"
      viewBox={`0 0 ${W} ${H}`}
      preserveAspectRatio="xMidYMin slice"
      fill="none"
      stroke="currentColor"
      stroke-width="1"
      aria-hidden="true"
    >
      {edges.map(([a, b]) => (
        <path
          vector-effect="non-scaling-stroke"
          d={`M${a.x} ${a.y} Q${(a.x + b.x) / 2 + (b.y - a.y) * 0.12} ${(a.y + b.y) / 2 - (b.x - a.x) * 0.12} ${b.x} ${b.y}`}
        />
      ))}
      {nodes.map((n, i) => (
        <circle cx={n.x} cy={n.y} r={i % 5 === 0 ? 3 : 2} fill="currentColor" stroke="none" />
      ))}
    </svg>
  )
}
