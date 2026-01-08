import { createClient } from "@/lib/supabase/server";

export type UserRole = "client" | "admin";

/**
 * Check if user is an admin/agent
 * Returns 'admin' if user exists in agents table, 'client' otherwise
 */
export async function getUserRole(userId: string): Promise<UserRole> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("agents")
    .select("id")
    .eq("id", userId)
    .eq("active", true)
    .single();

  if (error || !data) {
    return "client";
  }

  return "admin";
}
