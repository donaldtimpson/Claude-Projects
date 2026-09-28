import Foundation

// MARK: - Geography content deck
//
// One embedded dataset that feeds every geography game (Flag Frenzy, Capital Clash…).
// Flags are emoji — no image assets, and they render crisp at any size. Mirrors the
// concept-doc idea: build a mechanic once, pour a deck into it.

struct GeoCountry: Identifiable, Hashable {
    let name: String
    let capital: String
    let continent: String
    let flag: String
    var id: String { name }
}

enum Geo {
    static let continents = ["Africa", "Asia", "Europe", "North America", "South America", "Oceania"]

    static let countries: [GeoCountry] = [
        // Europe
        .init(name: "France", capital: "Paris", continent: "Europe", flag: "🇫🇷"),
        .init(name: "Germany", capital: "Berlin", continent: "Europe", flag: "🇩🇪"),
        .init(name: "Spain", capital: "Madrid", continent: "Europe", flag: "🇪🇸"),
        .init(name: "Italy", capital: "Rome", continent: "Europe", flag: "🇮🇹"),
        .init(name: "United Kingdom", capital: "London", continent: "Europe", flag: "🇬🇧"),
        .init(name: "Portugal", capital: "Lisbon", continent: "Europe", flag: "🇵🇹"),
        .init(name: "Greece", capital: "Athens", continent: "Europe", flag: "🇬🇷"),
        .init(name: "Ireland", capital: "Dublin", continent: "Europe", flag: "🇮🇪"),
        .init(name: "Norway", capital: "Oslo", continent: "Europe", flag: "🇳🇴"),
        .init(name: "Sweden", capital: "Stockholm", continent: "Europe", flag: "🇸🇪"),
        .init(name: "Netherlands", capital: "Amsterdam", continent: "Europe", flag: "🇳🇱"),
        .init(name: "Switzerland", capital: "Bern", continent: "Europe", flag: "🇨🇭"),
        .init(name: "Poland", capital: "Warsaw", continent: "Europe", flag: "🇵🇱"),
        .init(name: "Russia", capital: "Moscow", continent: "Europe", flag: "🇷🇺"),
        // Asia
        .init(name: "China", capital: "Beijing", continent: "Asia", flag: "🇨🇳"),
        .init(name: "Japan", capital: "Tokyo", continent: "Asia", flag: "🇯🇵"),
        .init(name: "India", capital: "New Delhi", continent: "Asia", flag: "🇮🇳"),
        .init(name: "South Korea", capital: "Seoul", continent: "Asia", flag: "🇰🇷"),
        .init(name: "Thailand", capital: "Bangkok", continent: "Asia", flag: "🇹🇭"),
        .init(name: "Vietnam", capital: "Hanoi", continent: "Asia", flag: "🇻🇳"),
        .init(name: "Indonesia", capital: "Jakarta", continent: "Asia", flag: "🇮🇩"),
        .init(name: "Saudi Arabia", capital: "Riyadh", continent: "Asia", flag: "🇸🇦"),
        .init(name: "Turkey", capital: "Ankara", continent: "Asia", flag: "🇹🇷"),
        .init(name: "Philippines", capital: "Manila", continent: "Asia", flag: "🇵🇭"),
        // Africa
        .init(name: "Egypt", capital: "Cairo", continent: "Africa", flag: "🇪🇬"),
        .init(name: "Nigeria", capital: "Abuja", continent: "Africa", flag: "🇳🇬"),
        .init(name: "Kenya", capital: "Nairobi", continent: "Africa", flag: "🇰🇪"),
        .init(name: "South Africa", capital: "Pretoria", continent: "Africa", flag: "🇿🇦"),
        .init(name: "Morocco", capital: "Rabat", continent: "Africa", flag: "🇲🇦"),
        .init(name: "Ethiopia", capital: "Addis Ababa", continent: "Africa", flag: "🇪🇹"),
        .init(name: "Ghana", capital: "Accra", continent: "Africa", flag: "🇬🇭"),
        .init(name: "Tanzania", capital: "Dodoma", continent: "Africa", flag: "🇹🇿"),
        // North America
        .init(name: "United States", capital: "Washington, D.C.", continent: "North America", flag: "🇺🇸"),
        .init(name: "Canada", capital: "Ottawa", continent: "North America", flag: "🇨🇦"),
        .init(name: "Mexico", capital: "Mexico City", continent: "North America", flag: "🇲🇽"),
        .init(name: "Cuba", capital: "Havana", continent: "North America", flag: "🇨🇺"),
        .init(name: "Jamaica", capital: "Kingston", continent: "North America", flag: "🇯🇲"),
        .init(name: "Guatemala", capital: "Guatemala City", continent: "North America", flag: "🇬🇹"),
        // South America
        .init(name: "Brazil", capital: "Brasília", continent: "South America", flag: "🇧🇷"),
        .init(name: "Argentina", capital: "Buenos Aires", continent: "South America", flag: "🇦🇷"),
        .init(name: "Chile", capital: "Santiago", continent: "South America", flag: "🇨🇱"),
        .init(name: "Peru", capital: "Lima", continent: "South America", flag: "🇵🇪"),
        .init(name: "Colombia", capital: "Bogotá", continent: "South America", flag: "🇨🇴"),
        .init(name: "Venezuela", capital: "Caracas", continent: "South America", flag: "🇻🇪"),
        // Oceania
        .init(name: "Australia", capital: "Canberra", continent: "Oceania", flag: "🇦🇺"),
        .init(name: "New Zealand", capital: "Wellington", continent: "Oceania", flag: "🇳🇿"),
        .init(name: "Fiji", capital: "Suva", continent: "Oceania", flag: "🇫🇯"),
    ]

    static func inContinent(_ c: String) -> [GeoCountry] { countries.filter { $0.continent == c } }

    /// A shortlist of countries a 7–12-year-old is likely to have heard of — used by the
    /// easier games so the answers are actually gettable.
    static let famousNames: Set<String> = [
        "France", "Germany", "Spain", "Italy", "United Kingdom", "Greece",
        "Japan", "China", "India", "Egypt",
        "United States", "Canada", "Mexico",
        "Brazil", "Argentina", "Australia", "Russia",
    ]
    static var famous: [GeoCountry] { countries.filter { famousNames.contains($0.name) } }
}
