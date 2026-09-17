import { describe, it, expect } from "vitest";
import { DRILLS } from "@/lib/drills/registry";
import type { DrillDef, Level, Problem, NumericInput, ChoiceInput, FieldsInput } from "@/lib/drills/types";

// ---------------------------------------------------------------------------
// Property-style tests for the procedural drill generators.
//
// For each generator, at each level, generate MANY problems and assert the
// declared answer is actually correct — recomputed independently from the
// problem's own prompt wherever feasible, rather than trusting the generator's
// arithmetic. Where an independent recompute isn't feasible (geography/grammar
// banks pull answers from bundled data), we assert the weaker-but-still-real
// structural invariants: a valid, in-range correctIndex and a resolvable answer.
// ---------------------------------------------------------------------------

const REPS = 400;

function texOf(r: Problem["prompt"]): string {
  return typeof r === "string" ? r : r.tex;
}

// Every problem, regardless of drill, must satisfy these.
function assertStructurallyValid(p: Problem): void {
  expect(p.id).toBeTruthy();
  expect(p.prompt).toBeDefined();
  const input = p.input;
  switch (input.kind) {
    case "numeric": {
      expect(Number.isFinite(input.answer)).toBe(true);
      break;
    }
    case "choice": {
      expect(input.options.length).toBeGreaterThanOrEqual(2);
      expect(input.correctIndex).toBeGreaterThanOrEqual(0);
      expect(input.correctIndex).toBeLessThan(input.options.length);
      // Options must be distinct so there's exactly one right answer to pick.
      const keys = input.options.map((o) => (typeof o === "string" ? o : o.tex));
      expect(new Set(keys).size).toBe(keys.length);
      break;
    }
    case "fields": {
      expect(input.fields.length).toBeGreaterThan(0);
      for (const f of input.fields) expect(Number.isFinite(f.answer)).toBe(true);
      break;
    }
    case "mapTap": {
      expect(input.targetId).toBeTruthy();
      break;
    }
  }
}

function drill(slug: string): DrillDef {
  const d = DRILLS.find((x) => x.slug === slug);
  if (!d) throw new Error(`drill ${slug} not found`);
  return d;
}

function eachLevel(d: DrillDef, fn: (p: Problem, level: Level) => void): void {
  for (const { value: level } of d.levels) {
    for (let i = 0; i < REPS; i++) {
      const p = d.generate(level);
      assertStructurallyValid(p);
      fn(p, level);
    }
  }
}

const numAnswer = (p: Problem) => (p.input as NumericInput).answer;
// Normalize -0 → 0 so signed-zero from a recompute (e.g. -1 * 0) doesn't trip
// Object.is-based `.toBe`. The drill values themselves are integers; only our
// independent recompute can produce a -0.
const z = (n: number) => n + 0;
const choiceCorrectTex = (p: Problem) => {
  const input = p.input as ChoiceInput;
  const o = input.options[input.correctIndex];
  return typeof o === "string" ? o : o.tex;
};

// ---- Every drill: universal structural invariants --------------------------
describe("all drills — structural invariants", () => {
  for (const d of DRILLS) {
    it(`${d.slug}: generates valid problems at every level`, () => {
      // Fewer reps here (grammar/geo banks are large but we just need coverage).
      for (const { value: level } of d.levels) {
        for (let i = 0; i < 60; i++) assertStructurallyValid(d.generate(level));
      }
    });
  }
});

// ---- Arithmetic: parse the prompt "a op b" and recompute -------------------
describe("arithmetic — answer matches an independent recompute of the prompt", () => {
  const d = drill("arithmetic");
  it("+ − × ÷ all compute correctly", () => {
    eachLevel(d, (p) => {
      // prompt tex: "a \times b" / "a \div b" / "a + b" / "a - b"
      const m = texOf(p.prompt).match(/^(-?\d+)\s*(\\times|\\div|\+|-)\s*(-?\d+)$/);
      expect(m).not.toBeNull();
      const a = Number(m![1]);
      const b = Number(m![3]);
      const op = m![2];
      let expected: number;
      if (op === "+") expected = a + b;
      else if (op === "-") expected = a - b;
      else if (op === "\\times") expected = a * b;
      else expected = a / b;
      expect(numAnswer(p)).toBe(expected);
      // Inverse-family invariants: differences non-negative, quotients integer.
      if (op === "-") expect(numAnswer(p)).toBeGreaterThanOrEqual(0);
      if (op === "\\div") expect(Number.isInteger(numAnswer(p))).toBe(true);
    });
  });
});

// ---- Percentages -----------------------------------------------------------
describe("percentages — answer equals p% of n", () => {
  const d = drill("percentages");
  it("recomputes p/100 * n", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(/^(\d+)\\%\\ \\text\{of\}\\ (\d+)$/);
      expect(m).not.toBeNull();
      const pct = Number(m![1]);
      const n = Number(m![2]);
      expect(numAnswer(p)).toBeCloseTo((pct * n) / 100, 9);
    });
  });
});

// ---- Order of operations ---------------------------------------------------
describe("order-of-operations — PEMDAS respected", () => {
  const d = drill("order-of-operations");
  it("multiplication binds before addition either way round", () => {
    eachLevel(d, (p) => {
      const tex = texOf(p.prompt);
      let expected: number;
      let m = tex.match(/^(\d+) \+ (\d+) \\times (\d+)$/);
      if (m) {
        expected = Number(m[1]) + Number(m[2]) * Number(m[3]);
      } else {
        m = tex.match(/^(\d+) \\times (\d+) \+ (\d+)$/);
        expect(m).not.toBeNull();
        expected = Number(m![1]) * Number(m![2]) + Number(m![3]);
      }
      expect(numAnswer(p)).toBe(expected);
    });
  });
});

// ---- Powers of two ---------------------------------------------------------
describe("powers-of-two — answer is 2^k", () => {
  const d = drill("powers-of-two");
  it("recomputes 2**k from the exponent in the prompt", () => {
    eachLevel(d, (p) => {
      const k = Number(texOf(p.prompt).match(/^2\^\{(\d+)\}$/)![1]);
      expect(numAnswer(p)).toBe(2 ** k);
    });
  });
});

// ---- Squares & roots -------------------------------------------------------
describe("squares — n^2 and sqrt", () => {
  const d = drill("squares");
  it("square and root both correct", () => {
    eachLevel(d, (p) => {
      const tex = texOf(p.prompt);
      const sq = tex.match(/^(\d+)\^2$/);
      const rt = tex.match(/^\\sqrt\{(\d+)\}$/);
      if (sq) {
        const n = Number(sq[1]);
        expect(numAnswer(p)).toBe(n * n);
      } else {
        expect(rt).not.toBeNull();
        const inside = Number(rt![1]);
        expect(numAnswer(p) * numAnswer(p)).toBe(inside);
        expect(Number.isInteger(numAnswer(p))).toBe(true);
      }
    });
  });
});

// ---- GCD -------------------------------------------------------------------
describe("gcd — answer divides both and is the greatest such", () => {
  const d = drill("gcd");
  function gcd(a: number, b: number): number {
    return b === 0 ? a : gcd(b, a % b);
  }
  it("matches Euclid on the two operands", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(/^\\gcd\((\d+),\\ (\d+)\)$/);
      expect(m).not.toBeNull();
      const a = Number(m![1]);
      const b = Number(m![2]);
      const g = numAnswer(p);
      expect(g).toBe(gcd(a, b));
      expect(a % g).toBe(0);
      expect(b % g).toBe(0);
    });
  });
});

// ---- Primes ----------------------------------------------------------------
describe("primes — correctIndex agrees with a fresh primality test", () => {
  const d = drill("primes");
  function isPrime(n: number): boolean {
    if (n < 2) return false;
    for (let i = 2; i * i <= n; i++) if (n % i === 0) return false;
    return true;
  }
  it("labels Prime (index 0) / Composite (index 1) correctly", () => {
    eachLevel(d, (p) => {
      const n = Number(texOf(p.prompt));
      const input = p.input as ChoiceInput;
      const chosen = input.options[input.correctIndex];
      const chosenLabel = typeof chosen === "string" ? chosen : chosen.tex;
      expect(chosenLabel).toBe(isPrime(n) ? "Prime" : "Composite");
    });
  });
});

// ---- Sequences -------------------------------------------------------------
describe("sequences — next term extends the pattern", () => {
  const d = drill("sequences");
  it("arithmetic (constant diff) or geometric (constant ratio) continues", () => {
    eachLevel(d, (p) => {
      // prompt: "t0,\ t1,\ t2,\ t3,\ ?"
      const nums = texOf(p.prompt)
        .replace(/,\\ \?$/, "")
        .split(/,\\ /)
        .map(Number);
      expect(nums).toHaveLength(4);
      const ans = numAnswer(p);
      const diff = nums[1] - nums[0];
      const isArithmetic = nums.every((v, i) => i === 0 || v - nums[i - 1] === diff);
      if (isArithmetic) {
        expect(ans).toBe(nums[3] + diff);
      } else {
        const ratio = nums[1] / nums[0];
        expect(ans).toBe(nums[3] * ratio);
      }
    });
  });
});

// ---- Logarithms ------------------------------------------------------------
describe("logarithms — answer k satisfies base^k = value", () => {
  const d = drill("logarithms");
  it("recomputes the exponent", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(/^\\log_\{(\d+)\}\((\d+)\)$/);
      expect(m).not.toBeNull();
      const base = Number(m![1]);
      const value = Number(m![2]);
      expect(base ** numAnswer(p)).toBe(value);
    });
  });
});

// ---- Derivatives (choice) --------------------------------------------------
describe("derivative — the correct option is d/dx(c x^n) = c·n x^(n-1)", () => {
  const d = drill("derivative");
  // Parse a power term "c x^{n}" / "c x" / "c" / "x^{n}" / "-x^{n}" into {c,n}.
  function parseTerm(tex: string): { c: number; n: number } {
    let m = tex.match(/^(-?\d*)x\^\{(-?\d+)\}$/);
    if (m) return { c: m[1] === "" ? 1 : m[1] === "-" ? -1 : Number(m[1]), n: Number(m[2]) };
    m = tex.match(/^(-?\d*)x$/);
    if (m) return { c: m[1] === "" ? 1 : m[1] === "-" ? -1 : Number(m[1]), n: 1 };
    m = tex.match(/^(-?\d+)$/);
    if (m) return { c: Number(m[1]), n: 0 };
    throw new Error(`unparseable term: ${tex}`);
  }
  it("differentiates the power term in the prompt", () => {
    eachLevel(d, (p) => {
      const inner = texOf(p.prompt).match(/\\frac\{d\}\{dx\}\\left\((.+)\\right\)/)![1];
      const { c, n } = parseTerm(inner);
      const dc = c * n;
      const dn = n - 1;
      const { c: cc, n: cn } = parseTerm(choiceCorrectTex(p));
      if (dc === 0) {
        expect(cc).toBe(0); // derivative is the constant 0
      } else {
        expect(cc).toBe(dc);
        expect(cn).toBe(dn);
      }
    });
  });
});

// ---- Integrals (choice) ----------------------------------------------------
describe("integral — the correct option differentiates back to the integrand", () => {
  const d = drill("integral");
  function parseTerm(tex: string): { c: number; n: number } {
    let m = tex.match(/^(-?\d*)x\^\{(-?\d+)\}$/);
    if (m) return { c: m[1] === "" ? 1 : m[1] === "-" ? -1 : Number(m[1]), n: Number(m[2]) };
    m = tex.match(/^(-?\d*)x$/);
    if (m) return { c: m[1] === "" ? 1 : m[1] === "-" ? -1 : Number(m[1]), n: 1 };
    m = tex.match(/^(-?\d+)$/);
    if (m) return { c: Number(m[1]), n: 0 };
    throw new Error(`unparseable term: ${tex}`);
  }
  it("d/dx of the antiderivative equals the integrand", () => {
    eachLevel(d, (p) => {
      const integrand = texOf(p.prompt).match(/\\int (.+)\\,dx/)![1];
      const { c, n } = parseTerm(integrand);
      // correct option is "<term> + C"
      const antideriv = choiceCorrectTex(p).replace(/ \+ C$/, "");
      const { c: ac, n: an } = parseTerm(antideriv);
      // Differentiate the antiderivative → should recover the integrand.
      expect(ac * an).toBe(c);
      expect(an - 1).toBe(n);
    });
  });
});

// ---- Determinant (choice) --------------------------------------------------
describe("determinant — correct option is ad − bc", () => {
  const d = drill("determinant");
  it("recomputes ad − bc from the matrix", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(
        /\\begin\{vmatrix\} (-?\d+) & (-?\d+) \\\\ (-?\d+) & (-?\d+) \\end\{vmatrix\}/,
      );
      expect(m).not.toBeNull();
      const [a, b, c, dd] = [m![1], m![2], m![3], m![4]].map(Number);
      expect(z(Number(choiceCorrectTex(p)))).toBe(z(a * dd - b * c));
    });
  });
});

// ---- Dot product (choice) --------------------------------------------------
describe("dot-product — correct option is a·b", () => {
  const d = drill("dot-product");
  it("recomputes a1 b1 + a2 b2", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(
        /\((-?\d+),\\ (-?\d+)\) \\cdot \((-?\d+),\\ (-?\d+)\)/,
      );
      expect(m).not.toBeNull();
      const [a1, a2, b1, b2] = [m![1], m![2], m![3], m![4]].map(Number);
      expect(z(Number(choiceCorrectTex(p)))).toBe(z(a1 * b1 + a2 * b2));
    });
  });
});

// ---- Matrix × vector (choice) ----------------------------------------------
describe("matrix-vector — correct option is the product (p, q)", () => {
  const d = drill("matrix-vector");
  it("recomputes each row dotted with the vector", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(
        /\\begin\{bmatrix\} (-?\d+) & (-?\d+) \\\\ (-?\d+) & (-?\d+) \\end\{bmatrix\}\\begin\{bmatrix\} (-?\d+) \\\\ (-?\d+) \\end\{bmatrix\}/,
      );
      expect(m).not.toBeNull();
      const [a, b, c, dd, x, y] = [m![1], m![2], m![3], m![4], m![5], m![6]].map(Number);
      const pair = choiceCorrectTex(p).match(/^\((-?\d+),\\ (-?\d+)\)$/);
      expect(pair).not.toBeNull();
      expect(z(Number(pair![1]))).toBe(z(a * x + b * y));
      expect(z(Number(pair![2]))).toBe(z(c * x + dd * y));
    });
  });
});

// ---- Solve the system (choice) ---------------------------------------------
describe("solve-system — the correct (x, y) satisfies both equations", () => {
  const d = drill("solve-system");
  // Parse "a x + b y = c" style with tidy signs into [a, b, c].
  function parseEq(eq: string): [number, number, number] {
    const cleaned = eq.replace(/\s+/g, "");
    const m = cleaned.match(/^(.*?)=(-?\d+)$/);
    if (!m) throw new Error(`bad eq: ${eq}`);
    const lhs = m[1];
    const c = Number(m[2]);
    let a = 0;
    let b = 0;
    // x term
    const xm = lhs.match(/(^|[+])(-?\d*)x/) || lhs.match(/(-)(\d*)x/);
    const xmatch = lhs.match(/(-?\d*)x/);
    if (xmatch) {
      const co = xmatch[1];
      a = co === "" || co === "+" ? 1 : co === "-" ? -1 : Number(co);
    }
    void xm;
    // y term: appears as "+Ny", "-Ny", "+y", "-y" (or leading if no x)
    const ym = lhs.match(/([+-]?)(\d*)y/);
    if (ym) {
      const sign = ym[1] === "-" ? -1 : 1;
      const mag = ym[2] === "" ? 1 : Number(ym[2]);
      b = sign * mag;
    }
    return [a, b, c];
  }
  it("the announced solution actually solves the system", () => {
    eachLevel(d, (p) => {
      const cases = texOf(p.prompt).match(/\\begin\{cases\} (.+?) \\\\ (.+?) \\end\{cases\}/);
      expect(cases).not.toBeNull();
      const [a1, b1, c1] = parseEq(cases![1]);
      const [a2, b2, c2] = parseEq(cases![2]);
      const pair = choiceCorrectTex(p).match(/^\((-?\d+),\\ (-?\d+)\)$/);
      expect(pair).not.toBeNull();
      const x = Number(pair![1]);
      const y = Number(pair![2]);
      expect(z(a1 * x + b1 * y)).toBe(z(c1));
      expect(z(a2 * x + b2 * y)).toBe(z(c2));
    });
  });
});

// ---- Unit circle (choice) --------------------------------------------------
// Independent check: recompute the exact value from the angle + function using a
// reference table, and confirm the generator's chosen correct option renders it.
describe("unit-circle — correct option is the true exact value", () => {
  const d = drill("unit-circle");
  // angle-tex → { sin, cos, tan } as canonical display strings (matching VALUES tex).
  const TABLE: Record<string, { sin: string; cos: string; tan: string }> = {
    "0": { sin: "0", cos: "1", tan: "0" },
    "\\tfrac{\\pi}{6}": { sin: "\\tfrac{1}{2}", cos: "\\tfrac{\\sqrt{3}}{2}", tan: "\\tfrac{\\sqrt{3}}{3}" },
    "\\tfrac{\\pi}{4}": { sin: "\\tfrac{\\sqrt{2}}{2}", cos: "\\tfrac{\\sqrt{2}}{2}", tan: "1" },
    "\\tfrac{\\pi}{3}": { sin: "\\tfrac{\\sqrt{3}}{2}", cos: "\\tfrac{1}{2}", tan: "\\sqrt{3}" },
    "\\tfrac{\\pi}{2}": { sin: "1", cos: "0", tan: "\\text{undefined}" },
    "\\tfrac{2\\pi}{3}": { sin: "\\tfrac{\\sqrt{3}}{2}", cos: "-\\tfrac{1}{2}", tan: "-\\sqrt{3}" },
    "\\tfrac{3\\pi}{4}": { sin: "\\tfrac{\\sqrt{2}}{2}", cos: "-\\tfrac{\\sqrt{2}}{2}", tan: "-1" },
    "\\tfrac{5\\pi}{6}": { sin: "\\tfrac{1}{2}", cos: "-\\tfrac{\\sqrt{3}}{2}", tan: "-\\tfrac{\\sqrt{3}}{3}" },
    "\\pi": { sin: "0", cos: "-1", tan: "0" },
    "\\tfrac{7\\pi}{6}": { sin: "-\\tfrac{1}{2}", cos: "-\\tfrac{\\sqrt{3}}{2}", tan: "\\tfrac{\\sqrt{3}}{3}" },
    "\\tfrac{5\\pi}{4}": { sin: "-\\tfrac{\\sqrt{2}}{2}", cos: "-\\tfrac{\\sqrt{2}}{2}", tan: "1" },
    "\\tfrac{4\\pi}{3}": { sin: "-\\tfrac{\\sqrt{3}}{2}", cos: "-\\tfrac{1}{2}", tan: "\\sqrt{3}" },
    "\\tfrac{3\\pi}{2}": { sin: "-1", cos: "0", tan: "\\text{undefined}" },
    "\\tfrac{5\\pi}{3}": { sin: "-\\tfrac{\\sqrt{3}}{2}", cos: "\\tfrac{1}{2}", tan: "-\\sqrt{3}" },
    "\\tfrac{7\\pi}{4}": { sin: "-\\tfrac{\\sqrt{2}}{2}", cos: "\\tfrac{\\sqrt{2}}{2}", tan: "-1" },
    "\\tfrac{11\\pi}{6}": { sin: "-\\tfrac{1}{2}", cos: "\\tfrac{\\sqrt{3}}{2}", tan: "-\\tfrac{\\sqrt{3}}{3}" },
  };
  it("matches the reference exact-value table", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(/^(\\sin|\\cos|\\tan)\\!\\left\((.+)\\right\)$/);
      expect(m).not.toBeNull();
      const fn = m![1] === "\\sin" ? "sin" : m![1] === "\\cos" ? "cos" : "tan";
      const angle = m![2];
      expect(TABLE[angle]).toBeDefined();
      expect(choiceCorrectTex(p)).toBe(TABLE[angle][fn as "sin" | "cos" | "tan"]);
    });
  });
});

// ---- Vector components (choice) --------------------------------------------
// Recompute r·cos or r·sin as an EXACT value (coeff·√root) and confirm the
// correct option renders it. Independent of the generator's scale() helper.
describe("vectors — correct option is the exact r·trig component", () => {
  const d = drill("vectors");
  // exact cos/sin at each degree as { coeff-over-2, root } relative to r.
  // We express the component as coeff·√root where component = r * trigValue.
  // trigValue table: value = a/2 * √root (a in {0,±1,±√2·..}) — encode directly.
  type Exact = { num: number; root: 1 | 2 | 3; den: number }; // num/den * √root
  const TRIG: Record<number, { cos: Exact; sin: Exact }> = {
    0: { cos: { num: 1, root: 1, den: 1 }, sin: { num: 0, root: 1, den: 1 } },
    30: { cos: { num: 1, root: 3, den: 2 }, sin: { num: 1, root: 1, den: 2 } },
    45: { cos: { num: 1, root: 2, den: 2 }, sin: { num: 1, root: 2, den: 2 } },
    60: { cos: { num: 1, root: 1, den: 2 }, sin: { num: 1, root: 3, den: 2 } },
    90: { cos: { num: 0, root: 1, den: 1 }, sin: { num: 1, root: 1, den: 1 } },
    120: { cos: { num: -1, root: 1, den: 2 }, sin: { num: 1, root: 3, den: 2 } },
    135: { cos: { num: -1, root: 2, den: 2 }, sin: { num: 1, root: 2, den: 2 } },
    150: { cos: { num: -1, root: 3, den: 2 }, sin: { num: 1, root: 1, den: 2 } },
    180: { cos: { num: -1, root: 1, den: 1 }, sin: { num: 0, root: 1, den: 1 } },
    210: { cos: { num: -1, root: 3, den: 2 }, sin: { num: -1, root: 1, den: 2 } },
    225: { cos: { num: -1, root: 2, den: 2 }, sin: { num: -1, root: 2, den: 2 } },
    240: { cos: { num: -1, root: 1, den: 2 }, sin: { num: -1, root: 3, den: 2 } },
    270: { cos: { num: 0, root: 1, den: 1 }, sin: { num: -1, root: 1, den: 1 } },
    300: { cos: { num: 1, root: 1, den: 2 }, sin: { num: -1, root: 3, den: 2 } },
    315: { cos: { num: 1, root: 2, den: 2 }, sin: { num: -1, root: 2, den: 2 } },
    330: { cos: { num: 1, root: 3, den: 2 }, sin: { num: -1, root: 1, den: 2 } },
  };
  function compTex(coeff: number, root: 1 | 2 | 3): string {
    if (coeff === 0) return "0";
    if (root === 1) return `${coeff}`;
    const r = root === 2 ? "\\sqrt{2}" : "\\sqrt{3}";
    if (coeff === 1) return r;
    if (coeff === -1) return `-${r}`;
    return `${coeff}${r}`;
  }
  it("component equals r·cosθ (x) or r·sinθ (y), exactly", () => {
    eachLevel(d, (p) => {
      const m = texOf(p.prompt).match(/\|\\vec\{v\}\| = (\d+),\\ \\theta = (\d+)\^\\circ\.\\quad (v_x|v_y) = \?/);
      expect(m).not.toBeNull();
      const r = Number(m![1]);
      const deg = Number(m![2]);
      const axis = m![3] === "v_x" ? "cos" : "sin";
      const e = TRIG[deg][axis];
      // component = r * (num/den) * √root ; r is even and den divides it cleanly.
      const coeff = (r * e.num) / e.den;
      expect(Number.isInteger(coeff)).toBe(true);
      expect(choiceCorrectTex(p)).toBe(compTex(coeff, e.root));
    });
  });
});

// ---- Geography + grammar banks: answer must resolve to a real option -------
// These pull answers from bundled data, not arithmetic, so we assert the
// invariant that matters: the declared correct answer is a valid, resolvable
// option (choice) or a real target region (mapTap).
describe("geography + grammar banks — declared answer is resolvable", () => {
  const bankSlugs = DRILLS.filter(
    (d) => d.subject === "Geography" || d.title.startsWith("Grammar") || d.poolSize,
  ).map((d) => d.slug);
  for (const slug of new Set(bankSlugs)) {
    it(`${slug}: correctIndex/target is always valid`, () => {
      const d = drill(slug);
      for (const { value: level } of d.levels) {
        for (let i = 0; i < 80; i++) {
          const p = d.generate(level);
          if (p.input.kind === "choice") {
            const input = p.input as ChoiceInput;
            const opt = input.options[input.correctIndex];
            expect(opt === undefined).toBe(false);
            expect(typeof opt === "string" ? opt : opt.tex).toBeTruthy();
          } else if (p.input.kind === "mapTap") {
            expect(p.input.targetId).toBeTruthy();
          }
        }
      }
    });
  }
});

// Guard: every registered drill actually appears above via the universal suite.
describe("registry", () => {
  it("has drills to test", () => {
    expect(DRILLS.length).toBeGreaterThan(20);
  });
  it("every drill has at least one level and a generate fn", () => {
    for (const d of DRILLS) {
      expect(d.levels.length).toBeGreaterThan(0);
      expect(typeof d.generate).toBe("function");
    }
  });
});
