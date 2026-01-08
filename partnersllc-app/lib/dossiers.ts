import { createClient } from "@/lib/supabase/server";

export type DossierStatus =
  | "QUALIFICATION"
  | "FORM_SUBMITTED"
  | "NM_PENDING"
  | "LLC_ACCEPTED"
  | "EIN_PENDING"
  | "BANK_PREPARATION"
  | "BANK_OPENED"
  | "WAITING_48H"
  | "CLOSED"
  | "ERROR";

export type DossierType = "LLC" | "CORP" | "BANKING";

export interface Dossier {
  id: string;
  user_id: string;
  product_id: string | null;
  type: DossierType;
  status: DossierStatus;
  current_step_instance_id: string | null;
  metadata: Record<string, any> | null;
  created_at: string;
  updated_at: string;
  completed_at: string | null;
}

export interface Step {
  id: string;
  code: string;
  label: string | null;
  position: number;
}

export interface StepInstance {
  id: string;
  dossier_id: string;
  step_id: string;
  started_at: string | null;
  completed_at: string | null;
  validation_status?:
    | "DRAFT"
    | "SUBMITTED"
    | "UNDER_REVIEW"
    | "APPROVED"
    | "REJECTED";
  rejection_reason?: string | null;
}

export interface Product {
  id: string;
  name: string;
  description: string | null;
}

export interface DocumentType {
  id: string;
  code: string;
  label: string;
  description: string | null;
  required_step_id: string | null;
  max_file_size_mb: number | null;
  allowed_extensions: string[] | null;
}

export interface TimelineEvent {
  id: string;
  event_type: string;
  entity_type: string;
  entity_id: string;
  actor_type: string | null;
  actor_id: string | null;
  payload: Record<string, any>;
  created_at: string;
}

export interface DossierWithDetails extends Dossier {
  product?: Product | null;
  current_step_instance?: (StepInstance & { step?: Step | null }) | null;
  step_instances?: (StepInstance & { step?: Step | null })[];
  completed_steps_count?: number;
  total_steps_count?: number;
  progress_percentage?: number;
  required_documents?: DocumentType[];
  timeline_events?: TimelineEvent[];
}

/**
 * Get all dossiers for the current authenticated user
 * RLS is enforced by Supabase
 */
export async function getUserDossiers(): Promise<DossierWithDetails[]> {
  const supabase = await createClient();

  // First, fetch dossiers
  const { data: dossiers, error: dossiersError } = await supabase
    .from("dossiers")
    .select("*")
    .order("created_at", { ascending: false });

  if (dossiersError) {
    console.error("Error fetching dossiers:", dossiersError);
    throw dossiersError;
  }

  if (!dossiers || dossiers.length === 0) {
    return [];
  }

  // Fetch related data for each dossier
  const dossiersWithDetails = await Promise.all(
    dossiers.map(async (dossier) => {
      // Fetch product
      let product: Product | null = null;
      if (dossier.product_id) {
        const { data: productData } = await supabase
          .from("products")
          .select("*")
          .eq("id", dossier.product_id)
          .single();
        product = productData as Product | null;
      }

      // Fetch step instances
      const { data: stepInstances } = await supabase
        .from("step_instances")
        .select("*")
        .eq("dossier_id", dossier.id);

      // Fetch steps for each step instance
      const stepInstancesWithSteps = await Promise.all(
        (stepInstances || []).map(async (si) => {
          const { data: step } = await supabase
            .from("steps")
            .select("*")
            .eq("id", si.step_id)
            .single();
          return {
            ...si,
            step: step as Step | null,
          };
        })
      );

      // Fetch current step instance if exists
      let currentStepInstance: (StepInstance & { step?: Step | null }) | null =
        null;
      if (dossier.current_step_instance_id) {
        const { data: currentSi } = await supabase
          .from("step_instances")
          .select("*")
          .eq("id", dossier.current_step_instance_id)
          .single();

        if (currentSi) {
          const { data: currentStep } = await supabase
            .from("steps")
            .select("*")
            .eq("id", currentSi.step_id)
            .single();

          currentStepInstance = {
            ...currentSi,
            step: currentStep as Step | null,
          };
        }
      }

      // Calculate progress
      const completedSteps = stepInstancesWithSteps.filter(
        (si) => si.completed_at !== null
      ).length;
      const totalSteps = stepInstancesWithSteps.length;
      const progressPercentage =
        totalSteps > 0 ? Math.round((completedSteps / totalSteps) * 100) : 0;

      return {
        ...dossier,
        product,
        current_step_instance: currentStepInstance,
        step_instances: stepInstancesWithSteps,
        completed_steps_count: completedSteps,
        total_steps_count: totalSteps,
        progress_percentage: progressPercentage,
      } as DossierWithDetails;
    })
  );

  return dossiersWithDetails;
}

/**
 * Get a single dossier by ID (with RLS enforcement)
 */
export async function getDossierById(
  dossierId: string
): Promise<DossierWithDetails | null> {
  const supabase = await createClient();

  const { data: dossier, error } = await supabase
    .from("dossiers")
    .select("*")
    .eq("id", dossierId)
    .single();

  if (error) {
    console.error("Error fetching dossier:", error);
    // If not found, return null instead of throwing
    if (error.code === "PGRST116") {
      return null;
    }
    throw error;
  }

  if (!dossier) {
    return null;
  }

  // Fetch related data
  let product: Product | null = null;
  if (dossier.product_id) {
    const { data: productData } = await supabase
      .from("products")
      .select("*")
      .eq("id", dossier.product_id)
      .single();
    product = productData as Product | null;
  }

  // Fetch step instances
  const { data: stepInstances } = await supabase
    .from("step_instances")
    .select("*")
    .eq("dossier_id", dossier.id);

  // Fetch steps for each step instance
  const stepInstancesWithSteps = await Promise.all(
    (stepInstances || []).map(async (si) => {
      const { data: step } = await supabase
        .from("steps")
        .select("*")
        .eq("id", si.step_id)
        .single();
      return {
        ...si,
        step: step as Step | null,
      };
    })
  );

  // Fetch current step instance if exists
  let currentStepInstance: (StepInstance & { step?: Step | null }) | null =
    null;
  if (dossier.current_step_instance_id) {
    const { data: currentSi } = await supabase
      .from("step_instances")
      .select("*")
      .eq("id", dossier.current_step_instance_id)
      .single();

    if (currentSi) {
      const { data: currentStep } = await supabase
        .from("steps")
        .select("*")
        .eq("id", currentSi.step_id)
        .single();

      currentStepInstance = {
        ...currentSi,
        step: currentStep as Step | null,
      };
    }
  }

  // Calculate progress
  const completedSteps = stepInstancesWithSteps.filter(
    (si) => si.completed_at !== null
  ).length;
  const totalSteps = stepInstancesWithSteps.length;
  const progressPercentage =
    totalSteps > 0 ? Math.round((completedSteps / totalSteps) * 100) : 0;

  // Fetch required documents for current step if exists
  let requiredDocuments: DocumentType[] = [];
  if (currentStepInstance?.step?.id) {
    const { data: documentTypes } = await supabase
      .from("document_types")
      .select("*")
      .eq("required_step_id", currentStepInstance.step.id);

    requiredDocuments = (documentTypes || []) as DocumentType[];
  }

  // Fetch timeline events for this dossier
  const { data: events } = await supabase
    .from("events")
    .select("*")
    .eq("entity_type", "dossier")
    .eq("entity_id", dossier.id)
    .order("created_at", { ascending: true });

  return {
    ...dossier,
    product,
    current_step_instance: currentStepInstance,
    step_instances: stepInstancesWithSteps,
    completed_steps_count: completedSteps,
    total_steps_count: totalSteps,
    progress_percentage: progressPercentage,
    required_documents: requiredDocuments,
    timeline_events: (events || []) as TimelineEvent[],
  } as DossierWithDetails;
}
