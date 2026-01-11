"use client";

import { useState } from "react";
import { StepInstanceWithFields } from "./StepValidationSection";
import { FieldValidationList } from "./FieldValidationList";
import { RejectionModal } from "./RejectionModal";
import { toast } from "sonner";

interface StepValidationCardProps {
  stepInstance: StepInstanceWithFields;
  onRefresh: () => void;
}

export function StepValidationCard({
  stepInstance,
  onRefresh,
}: StepValidationCardProps) {
  const [isExpanded, setIsExpanded] = useState(
    stepInstance.validation_status === "SUBMITTED" ||
    stepInstance.validation_status === "UNDER_REVIEW"
  );
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [isApproving, setIsApproving] = useState(false);

  const allFieldsApproved =
    stepInstance.total_fields_count > 0 &&
    stepInstance.approved_fields_count === stepInstance.total_fields_count;

  const handleApproveStep = async () => {
    if (!allFieldsApproved) {
      toast.error("Tous les champs doivent être approuvés avant de valider l'étape");
      return;
    }

    try {
      setIsApproving(true);
      const response = await fetch(
        `/api/admin/dossiers/${stepInstance.dossier_id}/steps/${stepInstance.id}/approve`,
        { method: "POST" }
      );

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || "Erreur lors de l'approbation");
      }

      toast.success("Étape validée avec succès");
      onRefresh();
    } catch (err) {
      console.error("Error approving step:", err);
      toast.error(err instanceof Error ? err.message : "Erreur lors de l'approbation");
    } finally {
      setIsApproving(false);
    }
  };

  const handleRejectStep = async (rejectionReason: string) => {
    try {
      const response = await fetch(
        `/api/admin/dossiers/${stepInstance.dossier_id}/steps/${stepInstance.id}/reject`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ rejection_reason: rejectionReason }),
        }
      );

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || "Erreur lors du rejet");
      }

      toast.success("Étape rejetée");
      setShowRejectModal(false);
      onRefresh();
    } catch (err) {
      console.error("Error rejecting step:", err);
      toast.error(err instanceof Error ? err.message : "Erreur lors du rejet");
    }
  };

  const getStatusBadge = (status: string) => {
    const badges: Record<string, { bg: string; text: string; label: string }> = {
      APPROVED: { bg: "bg-green-500/20", text: "text-green-400", label: "Approuvé" },
      PENDING: { bg: "bg-yellow-500/20", text: "text-yellow-400", label: "En attente" },
      REJECTED: { bg: "bg-red-500/20", text: "text-red-400", label: "Rejeté" },
      SUBMITTED: { bg: "bg-blue-500/20", text: "text-blue-400", label: "Soumis" },
      UNDER_REVIEW: { bg: "bg-purple-500/20", text: "text-purple-400", label: "En révision" },
      DRAFT: { bg: "bg-gray-500/20", text: "text-gray-400", label: "Brouillon" },
    };

    const badge = badges[status] || badges.DRAFT;
    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${badge.bg} ${badge.text}`}>
        {badge.label}
      </span>
    );
  };

  return (
    <>
      <div className="border border-brand-stroke rounded-lg overflow-hidden bg-brand-dark-bg/50">
        {/* Header */}
        <div
          className="p-4 cursor-pointer hover:bg-brand-dark-bg/30 transition-colors"
          onClick={() => setIsExpanded(!isExpanded)}
        >
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h3 className="text-lg font-semibold text-brand-text-primary">
                  {stepInstance.step_label}
                </h3>
                {getStatusBadge(stepInstance.validation_status)}
              </div>
              
              {stepInstance.step_description && (
                <p className="text-sm text-brand-text-secondary mb-3">
                  {stepInstance.step_description}
                </p>
              )}

              <div className="flex items-center gap-4 text-sm">
                <span className="text-brand-text-secondary">
                  <span className="font-medium text-brand-accent">
                    {stepInstance.approved_fields_count}
                  </span>
                  /{stepInstance.total_fields_count} champs validés
                </span>
                
                {stepInstance.validated_at && (
                  <span className="text-brand-text-secondary">
                    Validé le {new Date(stepInstance.validated_at).toLocaleDateString('fr-FR')}
                  </span>
                )}
              </div>

              {stepInstance.rejection_reason && (
                <div className="mt-3 p-3 bg-red-500/10 border border-red-500/30 rounded text-sm text-red-400">
                  <strong>Raison du rejet:</strong> {stepInstance.rejection_reason}
                </div>
              )}
            </div>

            <button className="ml-4 text-brand-text-secondary hover:text-brand-text-primary transition-colors">
              <i className={`fa-solid fa-chevron-${isExpanded ? "up" : "down"}`}></i>
            </button>
          </div>
        </div>

        {/* Fields List */}
        {isExpanded && (
          <div className="border-t border-brand-stroke p-4 bg-brand-dark-surface">
            <FieldValidationList
              dossierId={stepInstance.dossier_id}
              fields={stepInstance.fields}
              onRefresh={onRefresh}
            />

            {/* Step Actions */}
            {(stepInstance.validation_status === "SUBMITTED" ||
              stepInstance.validation_status === "UNDER_REVIEW") && (
              <div className="mt-4 pt-4 border-t border-brand-stroke flex items-center gap-3">
                <button
                  onClick={handleApproveStep}
                  disabled={!allFieldsApproved || isApproving}
                  className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                    allFieldsApproved && !isApproving
                      ? "bg-green-500 hover:bg-green-600 text-white"
                      : "bg-gray-500/30 text-gray-500 cursor-not-allowed"
                  }`}
                >
                  {isApproving ? (
                    <>
                      <i className="fa-solid fa-spinner fa-spin mr-2"></i>
                      Validation en cours...
                    </>
                  ) : (
                    <>
                      <i className="fa-solid fa-check mr-2"></i>
                      Valider l&apos;étape
                    </>
                  )}
                </button>

                <button
                  onClick={() => setShowRejectModal(true)}
                  className="px-4 py-2 rounded-lg font-medium bg-red-500/20 hover:bg-red-500/30 text-red-400 transition-colors"
                >
                  <i className="fa-solid fa-times mr-2"></i>
                  Rejeter l&apos;étape
                </button>

                {!allFieldsApproved && (
                  <span className="text-sm text-brand-text-secondary">
                    Tous les champs doivent être approuvés
                  </span>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Rejection Modal */}
      {showRejectModal && (
        <RejectionModal
          title="Rejeter l'étape"
          message="Veuillez indiquer la raison du rejet de cette étape. Le client recevra cette information."
          onConfirm={handleRejectStep}
          onCancel={() => setShowRejectModal(false)}
        />
      )}
    </>
  );
}
