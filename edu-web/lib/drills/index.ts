// Barrel for the drill generators, types, and rand helpers. Lets callers import
// from "@/lib/drills" instead of reaching into individual files. (These used to
// live in a shared workspace package during the short-lived React Native
// experiment; with the native iOS app they stay here in the web app.)
export * from "./types";
export * from "./registry";
export * from "./rand";
