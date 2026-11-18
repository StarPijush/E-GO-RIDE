import localFont from "next/font/local";

/**
 * Official E-GO typography.
 * Poppins drives headings, fares and brand moments; Inter drives body/UI text.
 * Files are copied from the Flutter customer app (E-go/assets/fonts).
 */
export const poppins = localFont({
  src: [
    { path: "../assets/fonts/poppins/Poppins-Regular.ttf", weight: "400", style: "normal" },
    { path: "../assets/fonts/poppins/Poppins-Medium.ttf", weight: "500", style: "normal" },
    { path: "../assets/fonts/poppins/Poppins-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "../assets/fonts/poppins/Poppins-Bold.ttf", weight: "700", style: "normal" },
    { path: "../assets/fonts/poppins/Poppins-ExtraBold.ttf", weight: "800", style: "normal" },
  ],
  variable: "--font-poppins",
  display: "swap",
  fallback: ["system-ui", "sans-serif"],
});

export const inter = localFont({
  src: [
    { path: "../assets/fonts/inter/Inter-Regular.ttf", weight: "400", style: "normal" },
    { path: "../assets/fonts/inter/Inter-Medium.ttf", weight: "500", style: "normal" },
    { path: "../assets/fonts/inter/Inter-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "../assets/fonts/inter/Inter-Bold.ttf", weight: "700", style: "normal" },
  ],
  variable: "--font-inter",
  display: "swap",
  fallback: ["system-ui", "sans-serif"],
});
