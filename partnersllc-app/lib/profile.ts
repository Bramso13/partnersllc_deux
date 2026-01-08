import { createClient } from "@/lib/supabase/server";
import type { UserProfile } from "@/types/user";

/**
 * Get the user profile with status (server-side)
 * Returns null if profile not found
 */
export async function getProfile(
  userId: string
): Promise<UserProfile | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (error || !data) {
    return null;
  }

  return data as UserProfile;
}
