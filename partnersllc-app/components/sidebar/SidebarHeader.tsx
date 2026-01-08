import Link from "next/link";
import type { UserRole } from "@/lib/user-role";

interface SidebarHeaderProps {
  role: UserRole;
}

export function SidebarHeader({ role }: SidebarHeaderProps) {
  if (role === "admin") {
    return (
      <div className="p-4 mb-8">
        <Link href="/admin" className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#2D3033] rounded-lg flex items-center justify-center">
            <i className="fa-solid fa-shield-halved text-[#00F0FF] text-lg"></i>
          </div>
          <div>
            <div className="text-xl font-bold text-[#F9F9F9] tracking-wide">
              PARTNERS
            </div>
            <div className="text-xs text-gray-500 mt-1 ml-0">Back-Office</div>
          </div>
        </Link>
      </div>
    );
  }

  // Client version - using logo placeholder
  return (
    <div className="p-4 mb-8">
      <Link href="/dashboard">
        <div className="h-9 w-auto">
          {/* Placeholder for logo - replace with actual logo image */}
          <div className="text-xl font-bold text-[#F9F9F9]">PARTNERS LLC</div>
        </div>
      </Link>
    </div>
  );
}
