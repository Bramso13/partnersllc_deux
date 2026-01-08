import type { User as SupabaseUser } from "@supabase/supabase-js";

export type User = SupabaseUser;

export interface Session {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  expires_at?: number;
  token_type: string;
  user: User;
}

export interface AuthError {
  message: string;
  status?: number;
}
