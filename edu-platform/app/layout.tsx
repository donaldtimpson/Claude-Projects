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

export const metadata: Metadata = {
  title: "The Timpson Lyceum",
  description: "A classical education in mathematics, logic, and philosophy.",
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
