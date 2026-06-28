// Tiny RNG + id helpers shared by the drill generators. generate() is only ever
// called client-side (in DrillPlayer), so Math.random is fine here.

let idCounter = 0;
// Unique-per-problem id for React keys.
export function pid(slug: string): string {
  idCounter += 1;
  return `${slug}-${idCounter}-${Math.floor(Math.random() * 1e6)}`;
}

// Inclusive integer in [min, max].
export function randInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export function pick<T>(arr: readonly T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

// Fisher–Yates shuffle (returns a new array).
export function shuffle<T>(arr: readonly T[]): T[] {
  const out = [...arr];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

// Pick `n` distinct items from a pool (excluding any in `exclude`).
export function sampleDistinct<T>(pool: readonly T[], n: number, exclude: Set<T> = new Set()): T[] {
  const candidates = pool.filter((x) => !exclude.has(x));
  return shuffle(candidates).slice(0, n);
}
