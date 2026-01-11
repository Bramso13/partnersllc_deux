import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { requireAdminAuth } from "@/lib/auth";
import crypto from "crypto";

export async function POST(request: NextRequest) {
  try {
    // Auth check
    await requireAdminAuth();

    const body = await request.json();
    const { prospect_email, prospect_name, product_id, expires_in_days } = body;

    // Validation
    if (!prospect_email || !product_id) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      );
    }

    const supabase = await createClient();

    // Generate unique token
    const token = crypto.randomBytes(16).toString("hex");

    // Calculate expiration date
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + (expires_in_days || 30));

    // Create payment link
    const { data, error } = await supabase
      .from("payment_links")
      .insert({
        token,
        prospect_email,
        prospect_name: prospect_name || null,
        product_id,
        expires_at: expiresAt.toISOString(),
        status: "ACTIVE",
        created_by: user.id,
      })
      .select()
      .single();

    if (error) {
      console.error("Error creating payment link:", error);
      return NextResponse.json(
        { error: "Failed to create payment link" },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      payment_link: data,
      url: `${process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"}/register/${token}`,
    });
  } catch (error) {
    console.error("Error in create payment link API:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
