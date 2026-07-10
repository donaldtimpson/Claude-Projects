import SiteHeader from "@/components/SiteHeader";
import { ToastProvider } from "@/components/Toast";

export default function SiteLayout({ children }: { children: React.ReactNode }) {
  return (
    <ToastProvider>
      <SiteHeader />
      {children}
    </ToastProvider>
  );
}
