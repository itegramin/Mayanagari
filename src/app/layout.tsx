import type { Metadata } from "next";
import type { ReactNode } from "react";
import { getLocale } from "@/lib/i18n";
import "./globals.css";

export const metadata: Metadata = {
  title: "Mayanagari — A city of a thousand stories",
  description: "An original, bilingual, India-inspired text RPG about neighbourhoods, community, and everyday adventure.",
};

export default async function RootLayout({ children }: { children: ReactNode }) {
  const locale = await getLocale();
  return (
    <html lang={locale}>
      <body>{children}</body>
    </html>
  );
}
