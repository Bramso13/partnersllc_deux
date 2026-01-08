"use client";

import { createRetryCheckoutSession } from "@/app/actions/checkout";
import { useState } from "react";

export function SuspendedStatus() {
  const [isLoading, setIsLoading] = useState(false);

  const handleCompletePayment = async () => {
    setIsLoading(true);
    try {
      // Get the user's order ID - this will be implemented when we have the order data
      // For now, we'll need to fetch it from the database
      const checkoutUrl = await createRetryCheckoutSession();
      if (checkoutUrl) {
        window.location.href = checkoutUrl;
      }
    } catch (error) {
      console.error("Error creating checkout session:", error);
      setIsLoading(false);
    }
  };

  return (
    <div className="bg-surface border border-red-500 rounded-lg p-6">
      <div className="flex items-center gap-3 mb-4">
        <span className="text-2xl">⚠️</span>
        <h2 className="text-xl font-semibold text-foreground">
          Paiement non réussi
        </h2>
      </div>
      <p className="text-text-secondary mb-6">
        Votre paiement n'a pas abouti. Veuillez compléter votre paiement pour
        accéder à votre dossier.
      </p>
      <button
        onClick={handleCompletePayment}
        disabled={isLoading}
        className="bg-accent hover:bg-accent/90 text-background font-medium px-6 py-3 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isLoading ? "Chargement..." : "Compléter le paiement"}
      </button>
    </div>
  );
}
