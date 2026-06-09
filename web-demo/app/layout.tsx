import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Aethera v2.0 - Visual Showcase",
  description: "Experience the revolutionary features of Aethera",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <style>{`
          @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@300;400;500;600;700&display=swap');
        `}</style>
      </head>
      <body className="bg-gradient-to-br from-slate-950 via-purple-950 to-slate-900 text-white">
        <div className="fixed inset-0 pointer-events-none overflow-hidden">
          <div className="absolute top-0 left-1/4 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl opacity-20" />
          <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-cyan-500/20 rounded-full blur-3xl opacity-20" />
        </div>
        <div className="relative z-10">{children}</div>
      </body>
    </html>
  );
}
