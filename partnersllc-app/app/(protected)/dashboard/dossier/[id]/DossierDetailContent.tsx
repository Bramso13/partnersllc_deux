"use client";

import { useSearchParams } from "next/navigation";
import { DossierWithDetails } from "@/lib/dossiers";
import { ProductStep } from "@/lib/workflow";
import { ProgressCard } from "@/components/dashboard/ProgressCard";
import { SidebarCards } from "@/components/dashboard/SidebarCards";
import { TimelineSection } from "@/components/dashboard/TimelineSection";
import { DocumentsSection } from "@/components/dashboard/DocumentsSection";
import { EmptyState } from "@/components/dashboard/EmptyState";
import { RejectionWarningBanner } from "@/components/dashboard/RejectionWarningBanner";
import Link from "next/link";
import { useState, useEffect } from "react";

interface DossierDetailContentProps {
  dossier: DossierWithDetails;
  productSteps: ProductStep[];
  initialStepId?: string;
}

export function DossierDetailContent({
  dossier,
  productSteps,
  initialStepId,
}: DossierDetailContentProps) {
  const searchParams = useSearchParams();
  const stepIdFromUrl = searchParams.get("step_id") || initialStepId;

  // Check for rejected steps and count rejected fields
  const rejectedSteps =
    dossier.step_instances?.filter(
      (si: any) => si.validation_status === "REJECTED"
    ) || [];

  const [rejectedFieldsCount, setRejectedFieldsCount] = useState(0);
  const [rejectedStepId, setRejectedStepId] = useState<string | undefined>();
  const [isLoadingRejections, setIsLoadingRejections] = useState(false);

  useEffect(() => {
    const fetchRejectedFields = async () => {
      if (rejectedSteps.length === 0) return;

      setIsLoadingRejections(true);
      try {
        let totalRejectedFields = 0;
        let firstRejectedStepId: string | undefined;

        for (const rejectedStep of rejectedSteps) {
          const response = await fetch(
            `/api/workflow/step-instance?dossier_id=${dossier.id}&step_id=${rejectedStep.step_id}`
          );

          if (response.ok) {
            const stepInstance = await response.json();
            if (stepInstance) {
              // Fetch rejected fields count
              const fieldsResponse = await fetch(
                `/api/workflow/step-fields?step_id=${rejectedStep.step_id}&step_instance_id=${stepInstance.id}`
              );

              if (fieldsResponse.ok) {
                const fields = await fieldsResponse.json();
                const rejectedFields = fields.filter(
                  (f: any) => f.validationStatus === "REJECTED"
                );

                totalRejectedFields += rejectedFields.length;
                if (!firstRejectedStepId && rejectedFields.length > 0) {
                  firstRejectedStepId = rejectedStep.step_id;
                }
              }
            }
          }
        }

        setRejectedFieldsCount(totalRejectedFields);
        setRejectedStepId(firstRejectedStepId);
      } catch (error) {
        console.error("Error fetching rejected fields:", error);
      } finally {
        setIsLoadingRejections(false);
      }
    };

    fetchRejectedFields();
  }, [rejectedSteps, dossier.id]);

  // If step_id is in URL, show workflow
  if (stepIdFromUrl && dossier.product_id) {
    return (
      <div>
        {/* Back button */}
        <Link
          href={`/dossier/${dossier.id}`}
          className="inline-flex items-center gap-2 text-brand-text-secondary hover:text-brand-text-primary mb-6 transition-colors"
        >
          <i className="fa-solid fa-arrow-left"></i>
          <span>Retour au dossier</span>
        </Link>

        {/* Rejection Warning Banner */}
        {rejectedFieldsCount > 0 && rejectedStepId && (
          <RejectionWarningBanner
            rejectedFieldsCount={rejectedFieldsCount}
            dossierId={dossier.id}
            stepId={rejectedStepId}
          />
        )}

        <EmptyState
          dossierId={dossier.id}
          productId={dossier.product_id}
          productName={dossier.product?.name || "Produit"}
          rejectedFieldsCount={
            rejectedFieldsCount > 0 ? rejectedFieldsCount : undefined
          }
          rejectedStepId={rejectedStepId}
          currentStepInstance={dossier.current_step_instance as any}
          initialStepId={stepIdFromUrl}
        />
      </div>
    );
  }

  // Otherwise, show dossier detail with all steps
  const estimatedCompletion = dossier.completed_at
    ? null
    : new Date(new Date().getTime() + 8 * 24 * 60 * 60 * 1000).toISOString();

  return (
    <div>
      {/* Header with back to dashboard */}
      <div className="mb-8">
        <Link
          href="/dashboard"
          className="inline-flex items-center gap-2 text-brand-text-secondary hover:text-brand-text-primary mb-4 transition-colors"
        >
          <i className="fa-solid fa-arrow-left"></i>
          <span>Retour au tableau de bord</span>
        </Link>
        <h1 className="text-3xl font-bold text-brand-text-primary">
          Dossier {dossier.product?.name || "LLC"}
        </h1>
        <p className="text-brand-text-secondary mt-1">
          Gérez votre dossier et complétez les étapes nécessaires
        </p>
      </div>

      {/* Rejection Warning Banner */}
      {!isLoadingRejections && rejectedFieldsCount > 0 && rejectedStepId && (
        <RejectionWarningBanner
          rejectedFieldsCount={rejectedFieldsCount}
          dossierId={dossier.id}
          stepId={rejectedStepId}
        />
      )}

      {/* Progress Overview Section */}
      <div id="progress-overview" className="grid grid-cols-12 gap-6 mb-8">
        <ProgressCard dossier={dossier} productSteps={productSteps} />
        <SidebarCards estimatedCompletion={estimatedCompletion || undefined} />
      </div>

      {/* Main Grid Section */}
      <div id="main-grid" className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <TimelineSection dossier={dossier} />
        {/* <DocumentsSection /> */}
      </div>
    </div>
  );
}
