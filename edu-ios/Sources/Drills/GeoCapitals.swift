import Foundation

// Capital cities for the "Capital of…" multiple-choice drills, keyed by the atlas
// region `id` (Natural Earth ADMIN for countries, state name for US states — see
// GeoData.swift). Only askable regions need an entry; the drill pools filter to ids
// present here, so an omission simply drops that region from the drill (never a crash).
//
// Judgment calls on multi-/contested-capital cases (the single answer used here):
//   Bolivia → Sucre (constitutional; La Paz is the seat of government)
//   South Africa → Pretoria (executive; also Cape Town / Bloemfontein)
//   Ivory Coast → Yamoussoukro (official; Abidjan is economic)
//   Tanzania → Dodoma (official; Dar es Salaam is largest)
//   Benin → Porto-Novo (official; Cotonou is the seat of government)
//   Netherlands → Amsterdam (constitutional; The Hague is the seat of government)
//   Sri Lanka → Sri Jayawardenepura Kotte (official; Colombo is commercial)
//   eSwatini → Mbabane (administrative; Lobamba is royal/legislative)
//   Myanmar → Naypyidaw · Kazakhstan → Astana · Burundi → Gitega · Israel → Jerusalem
enum GeoCapitals {
    // Country id → capital. Grouped by continent to mirror the atlas for easy auditing.
    static let country: [String: String] = [
        // Africa
        "Algeria": "Algiers", "Angola": "Luanda", "Benin": "Porto-Novo", "Botswana": "Gaborone",
        "Burkina Faso": "Ouagadougou", "Burundi": "Gitega", "Cameroon": "Yaoundé",
        "Central African Republic": "Bangui", "Chad": "N'Djamena",
        "Democratic Republic of the Congo": "Kinshasa", "Djibouti": "Djibouti", "Egypt": "Cairo",
        "Equatorial Guinea": "Malabo", "Eritrea": "Asmara", "Ethiopia": "Addis Ababa",
        "Gabon": "Libreville", "Gambia": "Banjul", "Ghana": "Accra", "Guinea": "Conakry",
        "Guinea-Bissau": "Bissau", "Ivory Coast": "Yamoussoukro", "Kenya": "Nairobi",
        "Lesotho": "Maseru", "Liberia": "Monrovia", "Libya": "Tripoli", "Madagascar": "Antananarivo",
        "Malawi": "Lilongwe", "Mali": "Bamako", "Mauritania": "Nouakchott", "Morocco": "Rabat",
        "Mozambique": "Maputo", "Namibia": "Windhoek", "Niger": "Niamey", "Nigeria": "Abuja",
        "Republic of the Congo": "Brazzaville", "Rwanda": "Kigali", "Senegal": "Dakar",
        "Sierra Leone": "Freetown", "Somalia": "Mogadishu", "South Africa": "Pretoria",
        "South Sudan": "Juba", "Sudan": "Khartoum", "Togo": "Lomé", "Tunisia": "Tunis",
        "Uganda": "Kampala", "United Republic of Tanzania": "Dodoma", "Zambia": "Lusaka",
        "Zimbabwe": "Harare", "eSwatini": "Mbabane",
        // Asia
        "Afghanistan": "Kabul", "Armenia": "Yerevan", "Azerbaijan": "Baku", "Bangladesh": "Dhaka",
        "Bhutan": "Thimphu", "Brunei": "Bandar Seri Begawan", "Cambodia": "Phnom Penh",
        "China": "Beijing", "Cyprus": "Nicosia", "East Timor": "Dili", "Georgia": "Tbilisi",
        "India": "New Delhi", "Indonesia": "Jakarta", "Iran": "Tehran", "Iraq": "Baghdad",
        "Israel": "Jerusalem", "Japan": "Tokyo", "Jordan": "Amman", "Kazakhstan": "Astana",
        "Kuwait": "Kuwait City", "Kyrgyzstan": "Bishkek", "Laos": "Vientiane", "Lebanon": "Beirut",
        "Malaysia": "Kuala Lumpur", "Mongolia": "Ulaanbaatar", "Myanmar": "Naypyidaw",
        "Nepal": "Kathmandu", "North Korea": "Pyongyang", "Oman": "Muscat", "Pakistan": "Islamabad",
        "Philippines": "Manila", "Qatar": "Doha", "Saudi Arabia": "Riyadh", "South Korea": "Seoul",
        "Sri Lanka": "Sri Jayawardenepura Kotte", "Syria": "Damascus", "Taiwan": "Taipei",
        "Tajikistan": "Dushanbe", "Thailand": "Bangkok", "Turkey": "Ankara",
        "Turkmenistan": "Ashgabat", "United Arab Emirates": "Abu Dhabi", "Uzbekistan": "Tashkent",
        "Vietnam": "Hanoi", "Yemen": "Sana'a",
        // Europe
        "Albania": "Tirana", "Austria": "Vienna", "Belarus": "Minsk", "Belgium": "Brussels",
        "Bosnia and Herzegovina": "Sarajevo", "Bulgaria": "Sofia", "Croatia": "Zagreb",
        "Czechia": "Prague", "Denmark": "Copenhagen", "Estonia": "Tallinn", "Finland": "Helsinki",
        "France": "Paris", "Germany": "Berlin", "Greece": "Athens", "Hungary": "Budapest",
        "Iceland": "Reykjavík", "Ireland": "Dublin", "Italy": "Rome", "Latvia": "Riga",
        "Lithuania": "Vilnius", "Luxembourg": "Luxembourg", "Moldova": "Chișinău",
        "Montenegro": "Podgorica", "Netherlands": "Amsterdam", "North Macedonia": "Skopje",
        "Norway": "Oslo", "Poland": "Warsaw", "Portugal": "Lisbon", "Republic of Serbia": "Belgrade",
        "Romania": "Bucharest", "Russia": "Moscow", "Slovakia": "Bratislava", "Slovenia": "Ljubljana",
        "Spain": "Madrid", "Sweden": "Stockholm", "Switzerland": "Bern", "Ukraine": "Kyiv",
        "United Kingdom": "London",
        // North America
        "Belize": "Belmopan", "Canada": "Ottawa", "Costa Rica": "San José", "Cuba": "Havana",
        "Dominican Republic": "Santo Domingo", "El Salvador": "San Salvador",
        "Guatemala": "Guatemala City", "Haiti": "Port-au-Prince", "Honduras": "Tegucigalpa",
        "Jamaica": "Kingston", "Mexico": "Mexico City", "Nicaragua": "Managua",
        "Panama": "Panama City", "The Bahamas": "Nassau", "Trinidad and Tobago": "Port of Spain",
        "United States of America": "Washington, D.C.",
        // Oceania
        "Australia": "Canberra", "Fiji": "Suva", "New Zealand": "Wellington",
        "Papua New Guinea": "Port Moresby", "Solomon Islands": "Honiara", "Vanuatu": "Port Vila",
        // South America
        "Argentina": "Buenos Aires", "Bolivia": "Sucre", "Brazil": "Brasília", "Chile": "Santiago",
        "Colombia": "Bogotá", "Ecuador": "Quito", "Guyana": "Georgetown", "Paraguay": "Asunción",
        "Peru": "Lima", "Suriname": "Paramaribo", "Uruguay": "Montevideo", "Venezuela": "Caracas",
    ]

    // US state id → capital.
    static let state: [String: String] = [
        "Alabama": "Montgomery", "Alaska": "Juneau", "Arizona": "Phoenix", "Arkansas": "Little Rock",
        "California": "Sacramento", "Colorado": "Denver", "Connecticut": "Hartford",
        "Delaware": "Dover", "Florida": "Tallahassee", "Georgia": "Atlanta", "Hawaii": "Honolulu",
        "Idaho": "Boise", "Illinois": "Springfield", "Indiana": "Indianapolis", "Iowa": "Des Moines",
        "Kansas": "Topeka", "Kentucky": "Frankfort", "Louisiana": "Baton Rouge", "Maine": "Augusta",
        "Maryland": "Annapolis", "Massachusetts": "Boston", "Michigan": "Lansing",
        "Minnesota": "Saint Paul", "Mississippi": "Jackson", "Missouri": "Jefferson City",
        "Montana": "Helena", "Nebraska": "Lincoln", "Nevada": "Carson City",
        "New Hampshire": "Concord", "New Jersey": "Trenton", "New Mexico": "Santa Fe",
        "New York": "Albany", "North Carolina": "Raleigh", "North Dakota": "Bismarck",
        "Ohio": "Columbus", "Oklahoma": "Oklahoma City", "Oregon": "Salem",
        "Pennsylvania": "Harrisburg", "Rhode Island": "Providence", "South Carolina": "Columbia",
        "South Dakota": "Pierre", "Tennessee": "Nashville", "Texas": "Austin",
        "Utah": "Salt Lake City", "Vermont": "Montpelier", "Virginia": "Richmond",
        "Washington": "Olympia", "West Virginia": "Charleston", "Wisconsin": "Madison",
        "Wyoming": "Cheyenne",
    ]
}
