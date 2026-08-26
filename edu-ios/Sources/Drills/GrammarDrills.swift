import Foundation

// Grammar drills — a wide catalog of multiple-choice grammar practice, loaded from the
// bundled Resources/Grammar/grammar.json (authored + reviewed content, so adding or editing
// questions never touches code). Each drill is a finite pool of items, so all three modes
// come for free: Practice (10/20/All), Learn (spaced-repetition mastery), and Rapid Fire.
//
// Item model: a prompt (the question/sentence, usually with a "___" blank), a small set of
// options, the index of the correct option, a one-line explanation, and a difficulty level
// (1 easy … 3 hard). Options are shuffled at play time; difficulty tiers filter like the
// geography pools (Easy = level 1, Medium = 1–2, Hard = all). No `.geoMap` diagram ⇒ these
// use the math-style reveal: pick → correct/incorrect coloring + explanation + tap onward.

struct GrammarItem {
    let id: String
    let level: Int
    let prompt: String
    let options: [String]
    let answer: Int        // index into `options` of the correct choice (pre-shuffle)
    let explain: String
}

private struct GrammarDrillSpec {
    let slug: String
    let title: String
    let blurb: String
    let icon: String
    let layout: String     // "grid" (short word tiles) | "list" (full-sentence rows) | "auto"
    let order: String      // "fixed" (stable slots for recurring option sets) | else shuffle
    let tier: Int          // CONCEPT difficulty 1–3 (its/it's = 1 … who/whom = 3). Drives the
                           // Gauntlet's Easy/Medium/Hard; the focused drill itself is untiered.
    let items: [GrammarItem]
}

extension DrillCatalog {
    // Loaded once. The focused per-topic drills, plus a "Gauntlet" capstone that mixes every
    // grammar item together (so you can't lean on "this is the its/it's drill" pattern-matching).
    private static let grammarSpecs: [GrammarDrillSpec] = loadGrammar()
    static let grammarDrills: [DrillDef] = grammarSpecs.map(makeGrammarDrill) + [grammarGauntlet]
    // Slugs in catalog order — populates the Grammar category row in DrillsView.
    static let grammarSlugs: [String] = grammarDrills.map(\.slug)

    // Build one problem from an item, honoring its source drill's layout + order:
    //  order "fixed"   → stable content-derived (case-insensitive alphabetical) slots, so a
    //                    RECURRING option set (its/it's, than/then, Active/Passive…) always lands
    //                    in the same place — read the question, don't re-hunt the moved word. The
    //                    correct slot still varies by meaning, so there's nothing to game.
    //  order otherwise → shuffled per play (options unique per item — sentence pickers, word
    //                    lists — so there's no position to memorize, and it kills authoring bias).
    private static func grammarProblem(_ it: GrammarItem, layout: String, order: String) -> DrillProblem {
        let correct = it.options[min(max(it.answer, 0), it.options.count - 1)]
        let opts = order == "fixed"
            ? it.options.sorted { $0.lowercased() < $1.lowercased() }
            : it.options.shuffled()
        return DrillProblem(
            prompt: it.prompt,
            input: .choice(options: opts, correctIndex: opts.firstIndex(of: correct) ?? 0),
            explanation: it.explain,
            dedupeKey: it.id,
            forceGrid: layout == "grid",
            forceList: layout == "list"
        )
    }

    private static func makeGrammarDrill(_ spec: GrammarDrillSpec) -> DrillDef {
        let items = spec.items
        let byId = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        // Difficulty tiers: Easy = level 1, Medium = 1–2, Hard = all. Never empty.
        func pool(_ level: Int) -> [GrammarItem] {
            let p = items.filter { $0.level <= level }
            return p.isEmpty ? items : p
        }
        func problem(_ it: GrammarItem) -> DrillProblem { grammarProblem(it, layout: spec.layout, order: spec.order) }
        // A single concept has no honest Easy/Medium/Hard — drill the whole pool; Learn mode
        // adapts. (Concept-level difficulty lives in the Gauntlet.) The `level` arg is ignored:
        // the runner always passes 3, so pool(3) = every item.
        return DrillDef(
            slug: spec.slug, title: spec.title, blurb: spec.blurb, icon: spec.icon,
            poolSize: { _ in items.count },
            poolItems: { _ in items.map(\.id) },
            problemForItem: { id, _ in problem(byId[id] ?? items[0]) },
            difficultyTiers: false
        ) { _ in
            // Share the catalog shuffle bag so Practice "All" walks every item once. Key on
            // "-L3" to match resetBag(slug, level: 3) — the runner starts untiered drills at
            // level 3, so a new "All" session gets a fresh full permutation.
            return problem(items[DrillCatalog.draw("\(spec.slug)-L3") { Array(0..<items.count) }])
        }
    }

    // The capstone: one big pool of EVERY grammar item, each rendered with its own source
    // drill's layout/order. Mixing topics defeats the "I recognize this drill's questions"
    // shortcut and makes a true test of the underlying rules. Supports all modes, incl. Learn
    // (mastery over the whole grammar set) and Practice "All" (literally every question once).
    private static var grammarGauntlet: DrillDef {
        struct Tagged { let item: GrammarItem; let layout: String; let order: String; let tier: Int }
        let all: [Tagged] = grammarSpecs.flatMap { s in
            s.items.map { Tagged(item: $0, layout: s.layout, order: s.order, tier: s.tier) }
        }
        let byId = Dictionary(all.map { ($0.item.id, $0) }, uniquingKeysWith: { a, _ in a })
        // Difficulty = CONCEPT tier, the axis that's actually meaningful for grammar. Easy draws
        // only foundational concepts (its/it's, a/an, plurals…); Medium adds mid concepts;
        // Hard adds the advanced ones (who/whom, me/I, spot-the-error). A real beginner→advanced
        // ladder, unlike sub-selecting one concept's sentences.
        func pool(_ level: Int) -> [Tagged] {
            let p = all.filter { $0.tier <= level }
            return p.isEmpty ? all : p
        }
        func problem(_ t: Tagged) -> DrillProblem { grammarProblem(t.item, layout: t.layout, order: t.order) }
        return DrillDef(
            slug: "grammar-gauntlet",
            title: "Grammar Gauntlet",
            blurb: "Every grammar drill mixed together — Easy to Hard by concept, no pattern to lean on.",
            icon: "\u{1F3C6}",
            poolSize: { pool($0).count },
            poolItems: { pool($0).map(\.item.id) },
            problemForItem: { id, _ in problem(byId[id] ?? all[0]) }
        ) { level in
            let p = pool(level)
            return problem(p[DrillCatalog.draw("grammar-gauntlet-L\(level)") { Array(0..<p.count) }])
        }
    }

    // MARK: - Lesson homework drills (bundled Resources/Grammar/lessons.json)
    // One drill per course lecture (Lesson 1 … Lesson N), authored to mirror that lesson's
    // slide practices with fresh examples. Same item schema as grammar.json, but each runs a
    // fixed 30-question homework set (sampled from a larger pool) and a flawless run earns a ✦.
    private static let lessonSpecs: [GrammarDrillSpec] = loadDrills(resource: "lessons")
    static let lessonDrills: [DrillDef] = lessonSpecs.map { spec in
        var def = makeGrammarDrill(spec)
        def.homeworkLength = 30      // 30 of the ~45 pool; the draw bag deals them distinct
        return def
    }
    // Slugs in lesson order (the file is already sorted by lesson number at build time).
    static let lessonSlugs: [String] = lessonDrills.map(\.slug)

    private static func loadGrammar() -> [GrammarDrillSpec] { loadDrills(resource: "grammar") }

    // Decode + validate a bundled drills JSON. Skips any malformed item rather than crashing, so
    // a single bad row can never take down the whole catalog. Fails loud (DEBUG) if the file
    // itself is missing/unreadable — that's a build mistake, not a runtime condition.
    private static func loadDrills(resource: String) -> [GrammarDrillSpec] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let drills = root["drills"] as? [[String: Any]]
        else {
            assertionFailure("GrammarDrills: could not load \(resource).json")
            return []
        }
        return drills.compactMap { d in
            guard let slug = d["slug"] as? String,
                  let title = d["title"] as? String,
                  let rows = d["items"] as? [[String: Any]] else { return nil }
            let items: [GrammarItem] = rows.compactMap { r in
                guard let id = r["id"] as? String,
                      let prompt = r["prompt"] as? String,
                      let options = r["options"] as? [String],
                      let answer = (r["answer"] as? NSNumber)?.intValue,
                      let explain = r["explain"] as? String,
                      options.count >= 2, answer >= 0, answer < options.count,
                      Set(options).count == options.count   // options must be distinct (shuffle keys on text)
                else { return nil }
                let level = (r["level"] as? NSNumber)?.intValue ?? 1
                return GrammarItem(id: id, level: level, prompt: prompt,
                                   options: options, answer: answer, explain: explain)
            }
            guard !items.isEmpty else { return nil }
            return GrammarDrillSpec(
                slug: slug, title: title,
                blurb: d["blurb"] as? String ?? "",
                icon: d["icon"] as? String ?? "✒️",
                layout: d["layout"] as? String ?? "auto",
                order: d["order"] as? String ?? "shuffle",
                tier: (d["tier"] as? NSNumber)?.intValue ?? 2,
                items: items
            )
        }
    }
}
