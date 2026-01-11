import { requireAdminAuth } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/server";
import { NextRequest, NextResponse } from "next/server";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await requireAdminAuth();
    const { id: dossierId } = await params;

    const supabase = await createAdminClient();

    // Query all step instances for dossier with field counts
    const { data: stepInstances, error: stepError } = await supabase
      .from("step_instances")
      .select(
        `
        id,
        dossier_id,
        step_id,
        assigned_to,
        started_at,
        completed_at,
        validation_status,
        rejection_reason,
        validated_by,
        validated_at,
        steps!inner (
          id,
          label,
          description
        )
      `
      )
      .eq("dossier_id", dossierId)
      .order("started_at", { ascending: true });

    if (stepError) {
      console.error("Error fetching step instances:", stepError);
      return NextResponse.json(
        { error: "Erreur lors de la récupération des étapes" },
        { status: 500 }
      );
    }

    // For each step instance, fetch fields and counts
    const stepInstancesWithFields = await Promise.all(
      (stepInstances || []).map(async (si) => {
        interface StepField {
          id: string;
          label: string;
          field_type: string;
          is_required: boolean;
          position: number;
        }

        interface FieldValueRow {
          id: string;
          step_instance_id: string;
          step_field_id: string;
          value: string | null;
          value_jsonb: Record<string, unknown> | null;
          validation_status: string;
          rejection_reason: string | null;
          reviewed_by: string | null;
          reviewed_at: string | null;
          step_fields: StepField | StepField[];
        }

        // Fetch fields for this step instance
        const { data: fields, error: fieldsError } = await supabase
          .from("step_field_values")
          .select(
            `
            id,
            step_instance_id,
            step_field_id,
            value,
            value_jsonb,
            validation_status,
            rejection_reason,
            reviewed_by,
            reviewed_at,
            step_fields!inner (
              id,
              label,
              field_type,
              is_required,
              position
            )
          `
          )
          .eq("step_instance_id", si.id)
          .order("step_fields(position)", { ascending: true });

        if (fieldsError) {
          console.error("Error fetching fields:", fieldsError);
        }

        // Transform fields to flat structure
        const transformedFields = (fields as FieldValueRow[] || []).map((f) => {
          const stepField = Array.isArray(f.step_fields) ? f.step_fields[0] : f.step_fields;
          return {
            id: f.id,
            step_instance_id: f.step_instance_id,
            step_field_id: f.step_field_id,
            value: f.value,
            value_jsonb: f.value_jsonb,
            validation_status: f.validation_status,
            rejection_reason: f.rejection_reason,
            reviewed_by: f.reviewed_by,
            reviewed_at: f.reviewed_at,
            field_label: stepField?.label || "Unknown",
            field_type: stepField?.field_type || "text",
            is_required: stepField?.is_required || false,
          };
        });

        // Count approved fields
        const approvedCount = transformedFields.filter(
          (f) => f.validation_status === "APPROVED"
        ).length;

        interface StepInfo {
          label: string;
          description: string | null;
        }

        return {
          id: si.id,
          dossier_id: si.dossier_id,
          step_id: si.step_id,
          assigned_to: si.assigned_to,
          started_at: si.started_at,
          completed_at: si.completed_at,
          validation_status: si.validation_status,
          rejection_reason: si.rejection_reason,
          validated_by: si.validated_by,
          validated_at: si.validated_at,
          step_label: (si.steps as unknown as StepInfo)?.label || "Unknown Step",
          step_description: (si.steps as unknown as StepInfo)?.description || null,
          approved_fields_count: approvedCount,
          total_fields_count: transformedFields.length,
          fields: transformedFields,
        };
      })
    );

    return NextResponse.json({ stepInstances: stepInstancesWithFields });
  } catch (error) {
    console.error("Error in validation endpoint:", error);
    return NextResponse.json(
      { error: "Erreur serveur" },
      { status: 500 }
    );
  }
}
