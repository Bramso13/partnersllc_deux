import { NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth";
import { getUserRole } from "@/lib/user-role";
import { getReviewChartData } from "@/lib/agent-metrics";

export async function GET(request: NextRequest) {
  try {
    const user = await requireAuth();
    const role = await getUserRole(user.id);

    if (role !== "admin") {
      return NextResponse.json(
        { error: "Unauthorized" },
        { status: 403 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const agentId = searchParams.get("agentId") || user.id;

    // Verify agentId matches current user or has permission
    if (agentId !== user.id) {
      return NextResponse.json(
        { error: "Unauthorized" },
        { status: 403 }
      );
    }

    const chartData = await getReviewChartData(agentId);

    return NextResponse.json(chartData);
  } catch (error) {
    console.error("Error fetching chart data:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}