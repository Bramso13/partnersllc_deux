import { createClient } from "@/lib/supabase/server";
import { StepField } from "@/types/qualification";

export interface Step {
  id: string;
  code: string;
  label: string;
  description: string | null;
  position: number;
}

export interface ProductStep {
  id: string;
  product_id: string;
  step_id: string;
  position: number;
  is_required: boolean;
  estimated_duration_hours: number | null;
  step: Step;
}

export interface ProductWithSteps {
  id: string;
  code: string;
  name: string;
  description: string | null;
  steps: ProductStep[];
}

/**
 * Get all steps for a product with their details
 */
export async function getProductSteps(
  productId: string
): Promise<ProductStep[]> {
  const supabase = await createClient();

  console.log(`[getProductSteps] Fetching product steps for product_id: ${productId}`);

  const { data: productSteps, error } = await supabase
    .from("product_steps")
    .select(
      `
      id,
      product_id,
      step_id,
      position,
      is_required,
      estimated_duration_hours,
      step:steps (
        id,
        code,
        label,
        description,
        position
      )
    `
    )
    .eq("product_id", productId)
    .order("position", { ascending: true });

  if (error) {
    console.error("[getProductSteps] Error fetching product steps:", error);
    throw error;
  }

  console.log(`[getProductSteps] Raw response:`, {
    count: productSteps?.length || 0,
    firstItem: productSteps?.[0] || null,
  });

  const mapped = (productSteps || []).map((ps) => {
    const mappedItem = {
      id: ps.id,
      product_id: ps.product_id,
      step_id: ps.step_id,
      position: ps.position,
      is_required: ps.is_required,
      estimated_duration_hours: ps.estimated_duration_hours,
      step: ps.step as Step,
    };
    
    if (!mappedItem.step) {
      console.warn(`[getProductSteps] Product step ${ps.id} has no step data:`, ps);
    }
    
    return mappedItem;
  });

  console.log(`[getProductSteps] Mapped ${mapped.length} product steps`);
  return mapped;
}

/**
 * Get step fields for a specific step
 */
export async function getStepFields(stepId: string): Promise<StepField[]> {
  const supabase = await createClient();

  const { data: stepFields, error } = await supabase
    .from("step_fields")
    .select("*")
    .eq("step_id", stepId)
    .order("position", { ascending: true });

  if (error) {
    console.error("Error fetching step fields:", error);
    throw error;
  }

  // Transform options if they're stored as JSONB
  const fields = (stepFields || []).map((field) => {
    let options = field.options;
    if (options && typeof options === "string") {
      try {
        options = JSON.parse(options);
      } catch {
        options = null;
      }
    }
    // If options is an array of strings, convert to {value, label} format
    if (Array.isArray(options) && options.length > 0) {
      if (typeof options[0] === "string") {
        options = options.map((opt) => ({ value: opt, label: opt }));
      }
    }

    return {
      ...field,
      options: options || null,
    } as StepField;
  });

  return fields;
}

/**
 * Get current step instance for a dossier
 */
export async function getCurrentStepInstance(dossierId: string) {
  const supabase = await createClient();

  const { data: dossier } = await supabase
    .from("dossiers")
    .select("current_step_instance_id")
    .eq("id", dossierId)
    .single();

  if (!dossier?.current_step_instance_id) {
    return null;
  }

  const { data: stepInstance, error } = await supabase
    .from("step_instances")
    .select(
      `
      id,
      dossier_id,
      step_id,
      started_at,
      completed_at,
      step:steps (
        id,
        code,
        label,
        description,
        position
      )
    `
    )
    .eq("id", dossier.current_step_instance_id)
    .single();

  if (error) {
    console.error("Error fetching step instance:", error);
    return null;
  }

  return {
    ...stepInstance,
    step: stepInstance.step as Step,
  };
}
