import Foundation

/// Shuffles inside each teaching group but never across them.
///
/// A fixed order gets memorised: a child starts reciting the sequence from
/// position rather than reading the card, and the deck stops testing anything. So
/// every deck reshuffles each time it is opened.
///
/// But not all order is arbitrary. Letter sets (s a t p i n first) and phonics
/// levels (CVC before digraphs before blends before silent e) ARE the teaching,
/// and shuffling across them would hand a beginner "strength" on card three.
/// Grouping keeps the progression and randomises everything inside it.
func shuffledWithin<T>(_ items: [T], by group: (T) -> Int) -> [T] {
    Dictionary(grouping: items, by: group)
        .sorted { $0.key < $1.key }
        .flatMap { $0.value.shuffled() }
}
