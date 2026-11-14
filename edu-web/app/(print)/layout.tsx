// Standalone layout for print/PDF pages — no site header, light background.
// The root layout's dark <body> background is not printed (browsers omit
// background colors by default), and the print page sets explicit dark text.
// data-theme="print" pins the brand colors so light mode doesn't restyle paper.
export default function PrintLayout({ children }: { children: React.ReactNode }) {
  return (
    <div data-theme="print" className="min-h-screen bg-white text-zinc-900">
      {children}
    </div>
  );
}
