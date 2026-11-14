type Question = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
};

export default function AttemptReview({
  questions,
  answers,
}: {
  questions: Question[];
  answers: (number | null)[];
}) {
  return (
    <ol className="space-y-6">
      {questions.map((question, qi) => {
        const chosen = answers[qi] ?? null;
        const isCorrect = chosen === question.correctIndex;
        return (
          <li key={question.id} className="space-y-2">
            <p className="text-parchment font-medium text-sm">
              <span className="text-parchment-dim mr-2">{qi + 1}.</span>
              {question.prompt}
            </p>
            <ul className="space-y-1">
              {question.options.map((opt, oi) => {
                let style = "px-3 py-2 rounded text-sm border ";
                if (oi === question.correctIndex) {
                  style += "border-green-500 bg-green-900 text-parchment font-medium relative pr-10 after:absolute after:right-4 after:top-1/2 after:-translate-y-1/2 after:font-ui after:font-bold after:content-['✓'] after:text-green-400";
                } else if (oi === chosen && !isCorrect) {
                  style += "border-red-500 bg-red-900 text-parchment relative pr-10 after:absolute after:right-4 after:top-1/2 after:-translate-y-1/2 after:font-ui after:font-bold after:content-['✗'] after:text-red-400";
                } else {
                  style += "border-crimson-700 bg-field text-parchment-dim";
                }
                return (
                  <li key={oi} className={style}>
                    <span className="font-medium mr-2">{String.fromCharCode(65 + oi)}.</span>
                    {opt}
                    {oi === question.correctIndex && (
                      <span className="ml-2 text-green-400 text-xs">✓ correct</span>
                    )}
                    {oi === chosen && !isCorrect && (
                      <span className="ml-2 text-red-400 text-xs">✗ your answer</span>
                    )}
                  </li>
                );
              })}
            </ul>
            {question.explanation && (
              <p className="text-xs text-parchment-dim pl-1">{question.explanation}</p>
            )}
          </li>
        );
      })}
    </ol>
  );
}
