import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import type { User, Session } from "@/types/auth";

/**
 * Get the current authenticated user (server-side)
 * Returns null if not authenticated
 */
export async function getUser(): Promise<User | null> {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return null;
  }

  return user;
}

/**
 * Get the current session (server-side)
 * Returns null if no active session
 */
export async function getSession(): Promise<Session | null> {
  const supabase = await createClient();
  const {
    data: { session },
    error,
  } = await supabase.auth.getSession();

  if (error || !session) {
    return null;
  }

  return session as Session;
}

/**
 * Sign out the current user (server-side)
 * Redirects to login page after sign out
 */
export async function signOut(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

/**
 * Require authentication - redirects to login if not authenticated
 * Use in Server Components or Server Actions
 */
export async function requireAuth(): Promise<User> {
  const user = await getUser();
  if (!user) {
    redirect("/login");
  }
  return user;
}
