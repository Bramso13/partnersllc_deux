"use client";

interface SidebarCardsProps {
  estimatedCompletion?: string;
  advisorName?: string;
  advisorRole?: string;
  advisorAvatar?: string;
}

export function SidebarCards({
  estimatedCompletion,
  advisorName,
  advisorRole,
  advisorAvatar,
}: SidebarCardsProps) {
  // Calculate days until completion
  const daysUntilCompletion = estimatedCompletion
    ? Math.ceil(
        (new Date(estimatedCompletion).getTime() - new Date().getTime()) /
          (1000 * 60 * 60 * 24)
      )
    : null;

  return (
    <div className="col-span-4 space-y-6">
      {/* Advisor Card */}
      <div className="bg-brand-dark-bg rounded-2xl p-6 card-hover">
        <h4 className="text-sm font-semibold text-brand-text-secondary mb-2">
          Votre conseiller
        </h4>
        <div className="flex items-center space-x-3">
          <img
            src={
              advisorAvatar ||
              "https://storage.googleapis.com/uxpilot-auth.appspot.com/avatars/avatar-5.jpg"
            }
            alt="Advisor"
            className="w-12 h-12 rounded-full object-cover"
          />
          <div>
            <p className="font-medium text-brand-text-primary">
              {advisorName || "Sophie Martin"}
            </p>
            <p className="text-xs text-brand-text-secondary">
              {advisorRole || "Spécialiste LLC"}
            </p>
          </div>
        </div>
      </div>

      {/* Estimated Completion Card */}
      <div className="bg-brand-dark-bg rounded-2xl p-6 card-hover">
        <h4 className="text-sm font-semibold text-brand-text-secondary mb-2">
          Achèvement estimé
        </h4>
        {estimatedCompletion ? (
          <>
            <p className="text-2xl font-bold text-brand-text-primary">
              {new Date(estimatedCompletion).toLocaleDateString("fr-FR", {
                day: "numeric",
                month: "long",
              })}
            </p>
            <p className="text-xs text-brand-text-secondary mt-1">
              {daysUntilCompletion !== null && daysUntilCompletion > 0
                ? `Dans ${daysUntilCompletion} jour${daysUntilCompletion > 1 ? "s" : ""} ouvrable${daysUntilCompletion > 1 ? "s" : ""}`
                : "Bientôt"}
            </p>
          </>
        ) : (
          <>
            <p className="text-2xl font-bold text-brand-text-primary">
              28 Janvier
            </p>
            <p className="text-xs text-brand-text-secondary mt-1">
              Dans 8 jours ouvrables
            </p>
          </>
        )}
      </div>
    </div>
  );
}
