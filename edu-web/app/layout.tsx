import type { Metadata } from "next";
import { Cinzel, Inter, Source_Serif_4 } from "next/font/google";
import SessionProvider from "@/components/SessionProvider";
import { THEME_INIT_SCRIPT } from "@/components/ThemeToggle";
import "./globals.css";

const cinzel = Cinzel({
  subsets: ["latin"],
  variable: "--font-cinzel",
  weight: ["400", "600", "700"],
});

// Reading text: sturdy enough for small sizes and projectors (see globals.css).
const sourceSerif = Source_Serif_4({
  subsets: ["latin"],
  variable: "--font-serif-body",
  axes: ["opsz"],
});

// UI chrome: labels, metadata, buttons.
const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

// Use `||` (not `??`) so an empty-string env var also falls back — an empty
// NEXT_PUBLIC_SITE_URL would make `new URL("")` throw at build time.
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || "https://timpson-lyceum.vercel.app";
const SITE_DESCRIPTION = "A classical education in mathematics, logic, and philosophy.";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "The Timpson Lyceum",
    template: "%s · The Timpson Lyceum",
  },
  description: SITE_DESCRIPTION,
  openGraph: {
    type: "website",
    siteName: "The Timpson Lyceum",
    title: "The Timpson Lyceum",
    description: SITE_DESCRIPTION,
    url: SITE_URL,
  },
  twitter: {
    card: "summary_large_image",
    title: "The Timpson Lyceum",
    description: SITE_DESCRIPTION,
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // suppressHydrationWarning: THEME_INIT_SCRIPT may set data-theme before hydration.
    <html lang="en" className={`${cinzel.variable} ${sourceSerif.variable} ${inter.variable} h-full antialiased`} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_INIT_SCRIPT }} />
      </head>
      <body className="min-h-full flex flex-col bg-crimson-950 text-parchment" suppressHydrationWarning>
          <SessionProvider>{children}</SessionProvider>
        </body>
    </html>
  );
}
