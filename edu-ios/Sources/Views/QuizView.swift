import SwiftUI

struct QuizView: View {
    let questions: [QuizQuestion]
    let onFinish: (_ score: Int, _ total: Int, _ answers: [Int?]) -> Void

    @State private var index = 0
    @State private var answers: [Int?]

    init(questions: [QuizQuestion], onFinish: @escaping (Int, Int, [Int?]) -> Void) {
        self.questions = questions
        self.onFinish = onFinish
        _answers = State(initialValue: Array(repeating: nil, count: questions.count))
    }

    var body: some View {
        let q = questions[index]
        MCQCard(
            prompt: q.prompt,
            options: q.options,
            correctIndex: q.correctIndex,
            explanation: q.explanation,
            progress: "Question \(index + 1) of \(questions.count)"
        ) { chosen, _ in
            answers[index] = chosen
            if index + 1 < questions.count {
                index += 1
            } else {
                let score = zip(answers, questions).reduce(0) { $0 + ($1.0 == $1.1.correctIndex ? 1 : 0) }
                onFinish(score, questions.count, answers)
            }
        }
        .id(q.id)
    }
}
