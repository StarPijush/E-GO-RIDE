
import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import { Providers } from "@/components/providers";

import { inter, poppins } from "./fonts";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "E-GO — Move your way",
    template: "%s · E-GO",
  },
  description:
    "Book a Toto e-rickshaw or bike around Jhargram with E-GO. A browser demo of the E-GO customer application.",
  applicationName: "E-GO",
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#FFC928",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`${poppins.variable} ${inter.variable}`}>
      <body className="min-h-dvh bg-surface font-sans text-navy antialiased">
        <a
          href="#main"
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-full focus:bg-brand focus:px-5 focus:py-2 focus:font-semibold focus:text-navy"
        >
          Skip to content
        </a>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
