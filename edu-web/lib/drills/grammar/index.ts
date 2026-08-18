// Grammar drills for the web — parity with the iOS "Grammar" and "Grammar Lessons"
// categories. Both banks are generated from content/grammar/ (see
// tools/grammar/build_app_content.py); edit the source there, never ./data.

import { bankDrills, type BankFile } from "./bank";
import lessonsData from "./data/lessons.json";
import practiceData from "./data/grammar.json";

// The Harvey lesson homework banks (Lesson 1…19), sorted by lesson number.
export const grammarLessonDrills = bankDrills(lessonsData as unknown as BankFile, "Grammar Lessons");

// The ✒️ rule/vocab practice drills (its/it's, who/whom, comma sense…).
export const grammarPracticeDrills = bankDrills(practiceData as unknown as BankFile, "Grammar");
