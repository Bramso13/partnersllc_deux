import { requireAuth } from "@/lib/auth";
import { getUserRole } from "@/lib/user-role";
import {
  clientNavConfig,
  adminNavConfig,
} from "@/lib/navigation-config";
import { SidebarProvider } from "@/components/sidebar/SidebarProvider";

export default async function ProtectedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await requireAuth();
  const role = await getUserRole(user.id);
  const navConfig = role === "admin" ? adminNavConfig : clientNavConfig;

  return (
    <SidebarProvider role={role} navConfig={navConfig}>
      {children}
    </SidebarProvider>
  );
}
