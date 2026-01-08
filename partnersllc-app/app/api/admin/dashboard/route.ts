import { NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth";
import { getUserRole } from "@/lib/user-role";
import {
  getAgentStats,
  getAgentActivityEvents,
  getAgentDossiers,
} from "@/lib/agent-metrics";

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

    const [stats, activities, dossiers] = await Promise.all([
      getAgentStats(agentId),
      getAgentActivityEvents(agentId, 20),
      getAgentDossiers(agentId),
    ]);

    return NextResponse.json({
      stats,
      activities,
      dossiers,
    });
  } catch (error) {
    console.error("Error fetching agent dashboard data:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}