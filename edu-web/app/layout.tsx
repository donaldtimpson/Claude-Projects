import type { Metadata } from "next";
import { Cinzel, EB_Garamond } from "next/font/google";
import SessionProvider from "@/components/SessionProvider";
import "./globals.css";

const cinzel = Cinzel({
  subsets: ["latin"],
  variable: "--font-cinzel",
  weight: ["400", "600", "700"],
});

const ebGaramond = EB_Garamond({
  subsets: ["latin"],
  variable: "--font-garamond",
  weight: ["400", "500", "600"],
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
    <html lang="en" className={`${cinzel.variable} ${ebGaramond.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col bg-crimson-950 text-parchment" suppressHydrationWarning>
          <SessionProvider>{children}</SessionProvider>
        </body>
    </html>
  );
}
