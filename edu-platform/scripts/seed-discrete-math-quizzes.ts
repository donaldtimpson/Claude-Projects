import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// Video IDs from DB (positions 1–21; position 0 / Lecture 0 is skipped)
const quizzes: {
  videoId: string;
  label: string;
  questions: { prompt: string; options: string[]; correctIndex: number; explanation: string }[];
}[] = [
  {
    videoId: "cmo1t2vm9001dynpwtxhbx0dh",
    label: "Quiz 1: Propositional Logic and Introduction",
    questions: [
      { prompt: "Mathematics is primarily about:", options: ["Memorizing formulas", "Following rules", "Understanding patterns and reasoning", "Doing calculations quickly"], correctIndex: 2, explanation: "Misconception: math = computation" },
      { prompt: "A \"good\" mathematical question is one that:", options: ["Has a long answer", "Has a clear, precise meaning", "Uses numbers", "Is difficult"], correctIndex: 1, explanation: "Clarity over difficulty" },
      { prompt: "Mathematical insight comes from:", options: ["Memorization", "Pattern recognition and reasoning", "Authority", "Guessing"], correctIndex: 1, explanation: "Core philosophy" },
      { prompt: "Struggling with a problem often means:", options: ["You are failing", "The problem is bad", "You are engaging deeply with it", "You should quit"], correctIndex: 2, explanation: "Mindset correction" },
      { prompt: "In mathematics, elegance refers to:", options: ["Length of solution", "Complexity", "Simplicity and insight", "Speed"], correctIndex: 2, explanation: "Aesthetic misconception" },
      { prompt: "Mathematical writing should be:", options: ["Vague", "Precise", "Long", "Symbol-heavy only"], correctIndex: 1, explanation: "Precision emphasis" },
      { prompt: "The statement \"x is large\" is:", options: ["Precise", "Ambiguous", "Always true", "Always false"], correctIndex: 1, explanation: "Ambiguity awareness" },
      { prompt: "Symbols in math:", options: ["Replace thinking", "Clarify ideas when used correctly", "Are optional", "Make things harder"], correctIndex: 1, explanation: "Symbol misuse" },
      { prompt: "Good mathematical communication:", options: ["Uses as many symbols as possible", "Explains reasoning clearly", "Avoids words", "Is short only"], correctIndex: 1, explanation: "Balance idea" },
      { prompt: "\"Let x be a number\" is:", options: ["A proof", "A definition setup", "A theorem", "A conclusion"], correctIndex: 1, explanation: "Structure awareness" },
    ],
  },
  {
    videoId: "cmo1t2vo6001fynpwldv4emqh",
    label: "Quiz 2: Predicate Logic, Identity, Definitions, and Theorems",
    questions: [
      { prompt: "A definition:", options: ["Can be vague", "Must be precise", "Is optional", "Is always intuitive"], correctIndex: 1, explanation: "Precision" },
      { prompt: "Definitions are:", options: ["Proven", "Assumed starting points", "Always obvious", "Derived from theorems"], correctIndex: 1, explanation: "Logical structure" },
      { prompt: "Changing a definition:", options: ["Has no effect", "Changes meaning of statements", "Only affects notation", "Is not allowed"], correctIndex: 1, explanation: "Importance of definitions" },
      { prompt: "Example of a definition:", options: ["\"All primes are odd\"", "\"A prime has exactly two positive divisors\"", "\"2 is prime\"", "\"Primes are useful\""], correctIndex: 1, explanation: "Definition vs theorem" },
      { prompt: "Definitions are used to:", options: ["Compute", "Clarify concepts", "Prove everything", "Replace logic"], correctIndex: 1, explanation: "Purpose" },
      { prompt: "A theorem is:", options: ["A guess", "A proven statement", "A definition", "An example"], correctIndex: 1, explanation: "Basic distinction" },
      { prompt: "\"If P then Q\" means:", options: ["P and Q always true", "Whenever P is true, Q is true", "Q causes P", "P equals Q"], correctIndex: 1, explanation: "Implication confusion" },
      { prompt: "\"If and only if\" means:", options: ["One direction", "Both directions", "Neither direction", "Random"], correctIndex: 1, explanation: "iff clarity" },
      { prompt: "A false implication can occur when:", options: ["P true, Q false", "P false, Q true", "Both true", "Both false"], correctIndex: 0, explanation: "Truth table intuition" },
      { prompt: "Vacuous truth occurs when:", options: ["Conclusion false", "Hypothesis false", "Both true", "Both false"], correctIndex: 1, explanation: "Big conceptual hurdle" },
    ],
  },
  {
    videoId: "cmo1t2vq6001hynpwk2qg1z4t",
    label: "Quiz 3: Proof, Counterexample, and Boolean Algebra",
    questions: [
      { prompt: "A proof:", options: ["Suggests truth", "Demonstrates truth logically", "Uses examples only", "Is optional"], correctIndex: 1, explanation: "Core idea" },
      { prompt: "An example:", options: ["Proves a statement", "Does not prove a general claim", "Is always enough", "Replaces proof"], correctIndex: 1, explanation: "Huge misconception" },
      { prompt: "Proving \"if and only if\" requires:", options: ["One direction", "Both directions", "No logic", "Example only"], correctIndex: 1, explanation: "Common error" },
      { prompt: "A valid proof must:", options: ["Be short", "Be logical and complete", "Use symbols", "Be elegant"], correctIndex: 1, explanation: "Substance over style" },
      { prompt: "\"Proof by example\" fails because:", options: ["Examples are wrong", "It doesn't cover all cases", "It's too long", "It's unclear"], correctIndex: 1, explanation: "Key teaching point" },
      { prompt: "A counterexample:", options: ["Proves a statement", "Disproves a universal statement", "Is irrelevant", "Is always large"], correctIndex: 1, explanation: "Core concept" },
      { prompt: "To disprove \"for all,\" you need:", options: ["Many examples", "One counterexample", "A proof", "A definition"], correctIndex: 1, explanation: "Efficiency insight" },
      { prompt: "If one counterexample exists:", options: ["Statement still true", "Statement false", "Depends", "Unknown"], correctIndex: 1, explanation: "Logic clarity" },
      { prompt: "Counterexamples must:", options: ["Be typical", "Satisfy conditions and break conclusion", "Be large", "Be random"], correctIndex: 1, explanation: "Structure" },
      { prompt: "Finding counterexamples requires:", options: ["Guessing", "Testing edge cases", "Memorizing", "Ignoring conditions"], correctIndex: 1, explanation: "Strategy" },
      { prompt: "\"AND\" is true when:", options: ["One true", "Both true", "Neither true", "Always true"], correctIndex: 1, explanation: "Basic logic" },
      { prompt: "\"OR\" is true when:", options: ["Both true only", "At least one true", "Both false", "Always false"], correctIndex: 1, explanation: "Inclusive OR confusion" },
      { prompt: "\"NOT\" does:", options: ["Keeps value", "Reverses truth value", "Adds value", "Multiplies value"], correctIndex: 1, explanation: "Negation clarity" },
      { prompt: "Statement \"P OR Q\" is false when:", options: ["P true", "Q true", "Both false", "Both true"], correctIndex: 2, explanation: "Truth table" },
      { prompt: "De Morgan's Law: NOT (P AND Q) equals:", options: ["NOT P AND NOT Q", "NOT P OR NOT Q", "P OR Q", "P AND Q"], correctIndex: 1, explanation: "Classic trap" },
    ],
  },
  {
    videoId: "cmo1t2vu8001jynpwf3anwgs8",
    label: "Quiz 4: Lists",
    questions: [
      { prompt: "A list differs from a set because:", options: ["Lists have no elements", "Order matters in lists", "Lists cannot repeat elements", "Sets allow order"], correctIndex: 1, explanation: "Core distinction" },
      { prompt: "The lists (1,2) and (2,1) are:", options: ["Equal", "Different", "Same set", "Undefined"], correctIndex: 1, explanation: "Order misconception" },
      { prompt: "Repetition in lists:", options: ["Not allowed", "Allowed", "Only once", "Always removed"], correctIndex: 1, explanation: "Set vs list confusion" },
      { prompt: "Number of 2-element lists from {a,b}:", options: ["2", "3", "4", "Infinite"], correctIndex: 2, explanation: "ab, ba, aa, bb" },
      { prompt: "Lists are also called:", options: ["Subsets", "Sequences", "Relations", "Functions"], correctIndex: 1, explanation: "Terminology" },
    ],
  },
  {
    videoId: "cmo1t2vw4001lynpwrib5bglo",
    label: "Quiz 5: Factorial, Sets, and Quantifiers",
    questions: [
      { prompt: "n! means:", options: ["n + (n−1)", "Product from 1 to n", "n²", "Sum to n"], correctIndex: 1, explanation: "Definition" },
      { prompt: "0! equals:", options: ["0", "1", "Undefined", "Infinite"], correctIndex: 1, explanation: "Classic misconception" },
      { prompt: "5! equals:", options: ["25", "120", "60", "720"], correctIndex: 1, explanation: "Basic check" },
      { prompt: "Factorial grows:", options: ["Linearly", "Slowly", "Very rapidly", "Constant"], correctIndex: 2, explanation: "Growth intuition" },
      { prompt: "n! counts:", options: ["Subsets", "Permutations of n items", "Combinations", "Relations"], correctIndex: 1, explanation: "Meaning" },
      { prompt: "Sets ignore:", options: ["Elements", "Order", "Membership", "Size"], correctIndex: 1, explanation: "Core property" },
      { prompt: "{1,2,2,3} equals:", options: ["{1,2,2,3}", "{1,2,3}", "{2,3}", "{1,3}"], correctIndex: 1, explanation: "No duplicates" },
      { prompt: "A ⊆ B means:", options: ["A equals B", "All elements of A are in B", "B is in A", "Disjoint"], correctIndex: 1, explanation: "Subset meaning" },
      { prompt: "Number of subsets of an n-element set:", options: ["n", "2n", "2^n", "n²"], correctIndex: 2, explanation: "Power set" },
      { prompt: "Power set:", options: ["Set of subsets", "Set of elements", "Union", "Intersection"], correctIndex: 0, explanation: "Definition" },
      { prompt: "\"For all\" means:", options: ["Some", "Every element", "None", "One"], correctIndex: 1, explanation: "Universal quantifier" },
      { prompt: "\"There exists\" means:", options: ["All", "At least one", "None", "Infinite"], correctIndex: 1, explanation: "Existential" },
      { prompt: "Negation of \"for all x, P(x)\":", options: ["For all x, not P(x)", "There exists x such that not P(x)", "There exists x such that P(x)", "None"], correctIndex: 1, explanation: "Critical misconception" },
      { prompt: "Negation of \"there exists x, P(x)\":", options: ["There exists x, not P(x)", "For all x, not P(x)", "Same statement", "None"], correctIndex: 1, explanation: "Duality" },
      { prompt: "Order of quantifiers matters:", options: ["Never", "Sometimes", "Always — can change meaning", "Only for large sets"], correctIndex: 2, explanation: "Huge conceptual hurdle" },
    ],
  },
  {
    videoId: "cmo1t2vy4001nynpwcgny7ygm",
    label: "Quiz 6: Set Operations and Combinatorial Proofs",
    questions: [
      { prompt: "Union means:", options: ["Common elements", "All elements in either set", "Only unique", "Difference"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Intersection means:", options: ["All elements", "Common elements", "Differences", "None"], correctIndex: 1, explanation: "Basic" },
      { prompt: "A ∩ B = ∅ means:", options: ["Same set", "Disjoint sets", "Equal size", "Infinite"], correctIndex: 1, explanation: "Interpretation" },
      { prompt: "|A ∪ B| equals:", options: ["|A| + |B|", "|A| + |B| − |A ∩ B|", "|A| − |B|", "|A| × |B|"], correctIndex: 1, explanation: "Inclusion-exclusion intro" },
      { prompt: "Cartesian product A × B:", options: ["Union", "Pairs (a,b)", "Subsets", "Intersections"], correctIndex: 1, explanation: "Common confusion" },
      { prompt: "Combinatorial proof:", options: ["Uses algebra", "Counts the same thing two ways", "Uses induction", "Uses contradiction"], correctIndex: 1, explanation: "Core idea" },
      { prompt: "If two counts differ:", options: ["Both correct", "At least one is wrong", "Always equal", "Undefined"], correctIndex: 1, explanation: "Logic check" },
      { prompt: "Key idea of combinatorial proof:", options: ["Guess", "Double counting", "Approximation", "Limits"], correctIndex: 1, explanation: "Strategy" },
      { prompt: "Combinatorial proofs show:", options: ["Equality of expressions", "Inequalities", "Definitions", "Graphs"], correctIndex: 0, explanation: "Purpose" },
      { prompt: "Advantage of combinatorial proofs:", options: ["Shorter always", "More intuitive meaning", "Always easier", "Avoids counting"], correctIndex: 1, explanation: "Insight" },
    ],
  },
  {
    videoId: "cmo1t2w04001pynpw34au03bj",
    label: "Quiz 7: Relations",
    questions: [
      { prompt: "A relation is:", options: ["A function", "A set of ordered pairs", "A subset", "A list"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Reflexive means:", options: ["(a,b) always in relation", "(a,a) for all a", "Symmetric", "Transitive"], correctIndex: 1, explanation: "Property confusion" },
      { prompt: "Symmetric means:", options: ["(a,b) ⇒ (b,a)", "(a,a)", "(a,b,c)", "None"], correctIndex: 0, explanation: "Common" },
      { prompt: "Transitive means:", options: ["(a,b) and (b,c) ⇒ (a,c)", "(a,a)", "(b,a)", "None"], correctIndex: 0, explanation: "Important" },
      { prompt: "A relation can be:", options: ["Only symmetric", "Any combination of properties", "Only one property", "None"], correctIndex: 1, explanation: "Flexibility" },
    ],
  },
  {
    videoId: "cmo1t2w21001rynpwhia125nv",
    label: "Quiz 8: Equivalence Relations and Partitions",
    questions: [
      { prompt: "An equivalence relation requires:", options: ["Reflexive, symmetric, and transitive", "Only symmetric", "Only transitive", "None"], correctIndex: 0, explanation: "Definition" },
      { prompt: "Equivalence class:", options: ["One element", "Set of related elements", "Subset", "List"], correctIndex: 1, explanation: "Concept" },
      { prompt: "Elements in the same equivalence class are:", options: ["Unrelated", "Equivalent", "Different", "Random"], correctIndex: 1, explanation: "Meaning" },
      { prompt: "Equivalence classes:", options: ["Overlap", "Do not overlap", "Are random", "Infinite always"], correctIndex: 1, explanation: "Partition idea" },
      { prompt: "Every element is:", options: ["In multiple classes", "In exactly one class", "In none", "In infinite classes"], correctIndex: 1, explanation: "Important" },
      { prompt: "A partition is:", options: ["Overlapping subsets", "Disjoint subsets covering the full set", "Random subsets", "Ordered pairs"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Each element of a partition:", options: ["In multiple parts", "In exactly one part", "In none", "Optional"], correctIndex: 1, explanation: "Key rule" },
      { prompt: "Partitions relate to:", options: ["Functions", "Equivalence relations", "Lists", "Graphs"], correctIndex: 1, explanation: "Connection" },
      { prompt: "Parts of a partition must:", options: ["Overlap", "Be disjoint", "Be equal size", "Be ordered"], correctIndex: 1, explanation: "Constraint" },
      { prompt: "Number of parts in a partition:", options: ["Always fixed", "Varies", "Always 2", "Infinite"], correctIndex: 1, explanation: "Flexibility" },
    ],
  },
  {
    videoId: "cmo1t2w3x001tynpwz61ky8nw",
    label: "Quiz 9: Binomial Coefficients and the Binomial Theorem",
    questions: [
      { prompt: "\"n choose k\" counts:", options: ["Permutations", "Combinations", "Lists", "Functions"], correctIndex: 1, explanation: "Core meaning" },
      { prompt: "Does order matter in combinations?", options: ["Yes", "No", "Sometimes", "Depends"], correctIndex: 1, explanation: "Distinction" },
      { prompt: "n choose 0:", options: ["0", "1", "n", "Undefined"], correctIndex: 1, explanation: "Edge case" },
      { prompt: "Pascal's triangle gives:", options: ["Factorials", "Binomial coefficients", "Sets", "Relations"], correctIndex: 1, explanation: "Recognition" },
      { prompt: "n choose k equals:", options: ["n!/k!", "n!/(k!(n−k)!)", "k!/n!", "n²"], correctIndex: 1, explanation: "Formula recall with structure" },
    ],
  },
  {
    videoId: "cmo1t2w5s001vynpw48aykv6u",
    label: "Quiz 10: Proof by Contradiction and Contrapositive",
    questions: [
      { prompt: "The contrapositive of \"If P then Q\" is:", options: ["If Q then P", "If not Q then not P", "If not P then not Q", "If P then not Q"], correctIndex: 1, explanation: "Common mix-up with converse" },
      { prompt: "A proof by contradiction assumes:", options: ["The statement is true", "The negation of the statement is true", "Both true", "Nothing"], correctIndex: 1, explanation: "Key structure" },
      { prompt: "If a contradiction arises:", options: ["Statement false", "Original statement true", "Both false", "Unknown"], correctIndex: 1, explanation: "Logical conclusion" },
      { prompt: "Contrapositive proofs work because:", options: ["They are shorter", "They are logically equivalent to the original", "They avoid logic", "They use examples"], correctIndex: 1, explanation: "Equivalence insight" },
      { prompt: "Proof by contradiction proves:", options: ["Existence", "Truth by impossibility of the negation", "Only false statements", "Nothing"], correctIndex: 1, explanation: "Concept clarity" },
    ],
  },
  {
    videoId: "cmo1t2w8w001xynpwev9kn7wd",
    label: "Quiz 11: Proof by Smallest Counterexample and Induction",
    questions: [
      { prompt: "The method of smallest counterexample assumes:", options: ["No counterexamples exist", "A smallest counterexample exists", "Infinite counterexamples", "No ordering"], correctIndex: 1, explanation: "Well-ordering principle" },
      { prompt: "It relies on:", options: ["Induction", "Well-ordering of the integers", "Probability", "Sets"], correctIndex: 1, explanation: "Foundation" },
      { prompt: "Strategy:", options: ["Guess", "Show a smaller counterexample exists → contradiction", "Count", "Define"], correctIndex: 1, explanation: "Core logic" },
      { prompt: "If a smaller counterexample exists:", options: ["No issue", "A contradiction arises", "Statement false", "Statement true"], correctIndex: 1, explanation: "Key step" },
      { prompt: "Used for:", options: ["Functions", "Proving universal statements about integers", "Counting", "Geometry"], correctIndex: 1, explanation: "Application" },
      { prompt: "Induction proves:", options: ["One case", "Infinitely many cases", "Finite sets", "Examples"], correctIndex: 1, explanation: "Core idea" },
      { prompt: "The base case is:", options: ["Optional", "A required starting point", "Always n=2", "Irrelevant"], correctIndex: 1, explanation: "Frequent mistake" },
      { prompt: "The inductive step assumes:", options: ["Statement false", "Statement true for n=k", "Statement true for all n", "Nothing"], correctIndex: 1, explanation: "Hypothesis clarity" },
      { prompt: "The inductive step then proves:", options: ["n=k", "n=k+1", "n=k−1", "n=0"], correctIndex: 1, explanation: "Structure" },
      { prompt: "A missing base case:", options: ["Is fine", "Makes the proof invalid", "Is a minor issue", "Still works"], correctIndex: 1, explanation: "Critical error" },
    ],
  },
  {
    videoId: "cmo1t2wav001zynpwxmz0x1bx",
    label: "Quiz 12: Functions and Function Composition",
    questions: [
      { prompt: "A function assigns:", options: ["Multiple outputs per input", "Exactly one output per input", "No outputs", "Infinite outputs"], correctIndex: 1, explanation: "Core definition" },
      { prompt: "The domain is:", options: ["Outputs", "Inputs", "Graph", "Range"], correctIndex: 1, explanation: "Terminology" },
      { prompt: "The range/image is:", options: ["Inputs", "Outputs actually achieved", "All possible outputs", "Domain"], correctIndex: 1, explanation: "Subtle distinction" },
      { prompt: "A one-to-one (injective) function has:", options: ["Multiple outputs per input", "Distinct inputs giving distinct outputs", "Same outputs allowed", "No outputs"], correctIndex: 1, explanation: "Injective idea" },
      { prompt: "An inverse function exists if the function is:", options: ["Constant", "One-to-one", "Many-to-one", "Undefined"], correctIndex: 1, explanation: "Key condition" },
      { prompt: "f∘g means:", options: ["Apply f then g", "Apply g then f", "Add the functions", "Multiply the functions"], correctIndex: 1, explanation: "Order confusion" },
      { prompt: "Composition requires:", options: ["Same domain", "Output of g fits the input of f", "Same range", "Nothing"], correctIndex: 1, explanation: "Compatibility" },
      { prompt: "The identity function:", options: ["Changes the input", "Leaves the input unchanged", "Outputs zero", "Is constant"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Function composition is:", options: ["Always commutative", "Not commutative in general", "Always equal", "Undefined"], correctIndex: 1, explanation: "Common misconception" },
      { prompt: "f∘identity equals:", options: ["Zero", "f", "Identity", "Undefined"], correctIndex: 1, explanation: "Neutral element" },
    ],
  },
  {
    videoId: "cmo1t2wct0021ynpwtiox5z2r",
    label: "Quiz 13: Permutations: Example of a Group",
    questions: [
      { prompt: "A permutation is:", options: ["A combination", "An ordered arrangement", "A subset", "A function"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Number of permutations of n elements:", options: ["n", "n!", "2^n", "n²"], correctIndex: 1, explanation: "Basic count" },
      { prompt: "Cycle notation:", options: ["Lists values in order", "Shows the mapping as cycles", "Represents sets", "Represents functions"], correctIndex: 1, explanation: "Concept" },
      { prompt: "A transposition is:", options: ["A swap of two elements", "A rotation of all elements", "The identity", "A subset"], correctIndex: 0, explanation: "Definition" },
      { prompt: "Permutations:", options: ["Ignore order", "Depend on order", "Are sets", "Are relations"], correctIndex: 1, explanation: "Core distinction" },
    ],
  },
  {
    videoId: "cmo1t2weq0023ynpwir795x43",
    label: "Quiz 14: Probabilities and Sample Spaces",
    questions: [
      { prompt: "The sample space is:", options: ["The set of all outcomes", "The set of events", "A probability value", "A function"], correctIndex: 0, explanation: "Definition" },
      { prompt: "An outcome is:", options: ["An event", "A single possible result", "A set", "A function"], correctIndex: 1, explanation: "Clarification" },
      { prompt: "The sample space must:", options: ["Be infinite", "Include all possible outcomes", "Be small", "Be numeric"], correctIndex: 1, explanation: "Completeness" },
      { prompt: "Probability is defined on:", options: ["Events only", "Sample space elements and subsets", "Functions", "Relations"], correctIndex: 1, explanation: "Structure" },
      { prompt: "Omitting outcomes from the sample space:", options: ["Is fine", "Produces an incorrect model", "Creates a smaller set", "Makes things easier"], correctIndex: 1, explanation: "Modeling issue" },
    ],
  },
  {
    videoId: "cmo1t2wgo0025ynpwdg0ewmnu",
    label: "Quiz 15: Probability, Events, Conditional Probability, and Independence",
    questions: [
      { prompt: "An event is:", options: ["A single outcome", "A subset of the sample space", "A function", "A number"], correctIndex: 1, explanation: "Definition" },
      { prompt: "The union of two events means:", options: ["Both happen", "Either one happens", "Neither happens", "One only"], correctIndex: 1, explanation: "Meaning" },
      { prompt: "The intersection of two events means:", options: ["Either happens", "Both happen", "None", "Random"], correctIndex: 1, explanation: "Meaning" },
      { prompt: "The complement of an event is:", options: ["The same event", "The event not occurring", "The union", "The intersection"], correctIndex: 1, explanation: "Basic" },
      { prompt: "The probability of a complement P(A') equals:", options: ["P(A)", "1 − P(A)", "0", "Infinite"], correctIndex: 1, explanation: "Formula" },
      { prompt: "Conditional probability:", options: ["Is always independent", "Depends on given information", "Is always the same", "Is always zero"], correctIndex: 1, explanation: "Definition" },
      { prompt: "P(A|B) means:", options: ["A then B", "Probability of A given B occurred", "B given A", "Intersection"], correctIndex: 1, explanation: "Notation confusion" },
      { prompt: "Independence means:", options: ["Events are equal", "P(A|B) = P(A)", "Always dependent", "Disjoint"], correctIndex: 1, explanation: "Key definition" },
      { prompt: "Independent events:", options: ["Affect each other", "Do not affect each other's probabilities", "Are always disjoint", "Are the same event"], correctIndex: 1, explanation: "Misconception" },
      { prompt: "Disjoint (mutually exclusive) events are:", options: ["Independent", "Not independent (if nonzero probability)", "The same", "Equal probability"], correctIndex: 1, explanation: "Big trap" },
    ],
  },
  {
    videoId: "cmo1t2wik0027ynpwubgdeuq5",
    label: "Quiz 16: Probability, Random Variables, and Expectation",
    questions: [
      { prompt: "A random variable is:", options: ["A random number", "A function from outcomes to numbers", "An event", "A set"], correctIndex: 1, explanation: "Definition" },
      { prompt: "A discrete random variable has:", options: ["Continuous values", "Countably many values", "Infinite values only", "None"], correctIndex: 1, explanation: "Classification" },
      { prompt: "The value of a random variable depends on:", options: ["The function itself", "The outcome of the experiment", "Probability only", "Time"], correctIndex: 1, explanation: "Clarification" },
      { prompt: "The same random variable:", options: ["Always takes the same value", "Takes different values for different outcomes", "Is constant", "Is zero"], correctIndex: 1, explanation: "Concept" },
      { prompt: "A random variable maps:", options: ["Events to numbers", "Outcomes to numbers", "Numbers to events", "Sets to sets"], correctIndex: 1, explanation: "Definition precision" },
    ],
  },
  {
    videoId: "cmo1t2wkf0029ynpwp3azpkvd",
    label: "Quiz 17: Probability, Expectation, and Variance",
    questions: [
      { prompt: "Expectation (expected value) is:", options: ["The most likely value", "The weighted average value", "The maximum", "The minimum"], correctIndex: 1, explanation: "Common confusion" },
      { prompt: "Linearity of expectation states:", options: ["E(X+Y) = E(X)+E(Y) always", "Only if independent", "Never", "Sometimes"], correctIndex: 0, explanation: "Important result" },
      { prompt: "Expectation depends on:", options: ["Outcomes only", "Probabilities and values", "Time", "Order"], correctIndex: 1, explanation: "Definition" },
      { prompt: "The expected value:", options: ["Must actually occur", "May not occur in reality", "Is always an integer", "Is always the maximum"], correctIndex: 1, explanation: "Misconception" },
      { prompt: "Variance measures:", options: ["The mean", "The spread of values", "The maximum", "Probability"], correctIndex: 1, explanation: "Concept" },
    ],
  },
  {
    videoId: "cmo1t2wne002bynpwl439msw2",
    label: "Quiz 18: Number Theory and Dividing",
    questions: [
      { prompt: "The division algorithm gives:", options: ["a = bq + r", "a = b + r", "a = qr", "a = bq"], correctIndex: 0, explanation: "Core identity" },
      { prompt: "The remainder r satisfies:", options: ["Any value", "0 ≤ r < b", "Negative only", "Infinite"], correctIndex: 1, explanation: "Constraint" },
      { prompt: "\"a divides b\" means:", options: ["a/b is an integer", "b = ak for some integer k", "a > b", "a = b"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Divisibility is:", options: ["Approximate", "Exact integer division", "A fraction", "Random"], correctIndex: 1, explanation: "Clarification" },
      { prompt: "If a|b and b|c then:", options: ["a|c always", "Not necessarily", "Only sometimes", "Never"], correctIndex: 0, explanation: "Transitivity" },
    ],
  },
  {
    videoId: "cmo1t2wpa002dynpw75v9iaz9",
    label: "Quiz 19: Number Theory, GCD, and Modular Arithmetic",
    questions: [
      { prompt: "gcd(a,b) is:", options: ["The largest common divisor", "The smallest", "Their product", "Their sum"], correctIndex: 0, explanation: "Definition" },
      { prompt: "gcd(0,a) equals:", options: ["0", "a", "1", "Undefined"], correctIndex: 1, explanation: "Edge case" },
      { prompt: "The Euclidean algorithm is:", options: ["Slow", "An efficient method to compute gcd", "Guessing", "Counting"], correctIndex: 1, explanation: "Method" },
      { prompt: "gcd(a,b)=1 means:", options: ["a equals b", "a and b are relatively prime", "Zero", "Infinite"], correctIndex: 1, explanation: "Meaning" },
      { prompt: "The gcd:", options: ["Is always 1", "Divides both numbers", "Is larger than both", "Is random"], correctIndex: 1, explanation: "Definition" },
      { prompt: "a ≡ b mod n means:", options: ["a equals b", "a and b have the same remainder mod n", "a > n", "b > n"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Modular addition:", options: ["Add normally then take mod", "Uses a different rule", "Multiply", "Divide"], correctIndex: 0, explanation: "Process" },
      { prompt: "A modular inverse of a mod n exists when:", options: ["Always", "gcd(a,n)=1", "a=0", "n=1"], correctIndex: 1, explanation: "Key condition" },
      { prompt: "Modular arithmetic:", options: ["Goes to infinity", "Wraps around values", "Is linear", "Is random"], correctIndex: 1, explanation: "Intuition" },
      { prompt: "The congruence relation is:", options: ["Not a relation", "An equivalence relation", "A function", "A set"], correctIndex: 1, explanation: "Connection" },
    ],
  },
  {
    videoId: "cmo1t2wr7002fynpwcjxnxdak",
    label: "Quiz 20: Modular Arithmetic, Chinese Remainder Theorem, and Factoring",
    questions: [
      { prompt: "The Chinese Remainder Theorem (CRT) applies when moduli are:", options: ["Equal", "Relatively prime", "Large", "Zero"], correctIndex: 1, explanation: "Key condition" },
      { prompt: "CRT guarantees:", options: ["No solution", "A unique solution mod the product", "Infinite solutions", "Exactly one integer solution"], correctIndex: 1, explanation: "Structure" },
      { prompt: "A system of congruences:", options: ["Is always inconsistent", "Can be solved simultaneously", "Is impossible", "Is random"], correctIndex: 1, explanation: "Purpose" },
      { prompt: "If the moduli are not coprime, CRT:", options: ["Still always works", "May fail", "Always fails", "Gives the same result"], correctIndex: 1, explanation: "Limitation" },
      { prompt: "The CRT solution is:", options: ["A unique integer", "A unique congruence class mod the product", "Infinite integers", "Zero"], correctIndex: 1, explanation: "Clarification" },
    ],
  },
  {
    videoId: "cmo1t2wt3002hynpwfs56yuuy",
    label: "Quiz 21: Fundamental Theorem of Arithmetic",
    questions: [
      { prompt: "A prime number has:", options: ["Any number of divisors", "Exactly two positive divisors", "Only odd divisors", "Only even divisors"], correctIndex: 1, explanation: "Definition" },
      { prompt: "The Fundamental Theorem of Arithmetic states:", options: ["There are infinite primes", "Every integer > 1 has a unique prime factorization", "No primes exist", "Factorization is random"], correctIndex: 1, explanation: "Core idea" },
      { prompt: "Are there infinitely many primes?", options: ["False", "True", "Unknown", "Depends"], correctIndex: 1, explanation: "Classic result" },
      { prompt: "If a number is composite, it is:", options: ["Prime", "A product of primes", "Zero", "Infinite"], correctIndex: 1, explanation: "Factorization" },
      { prompt: "√2 being irrational means:", options: ["It is a fraction", "It cannot be expressed as a ratio of integers", "It is an integer", "It is zero"], correctIndex: 1, explanation: "Concept" },
    ],
  },
];

async function main() {
  console.log("Seeding Discrete Math quizzes...");
  let total = 0;

  for (const quiz of quizzes) {
    const created = await prisma.quizQuestion.createMany({
      data: quiz.questions.map((q, i) => ({
        videoId: quiz.videoId,
        prompt: q.prompt,
        options: q.options,
        correctIndex: q.correctIndex,
        explanation: q.explanation,
        position: i,
      })),
    });
    console.log(`  ${quiz.label}: ${created.count} questions`);
    total += created.count;
  }

  console.log(`Done — ${total} questions inserted across ${quizzes.length} videos.`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
