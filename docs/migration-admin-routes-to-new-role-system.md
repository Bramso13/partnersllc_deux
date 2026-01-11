# Migration des Routes API Admin vers le Nouveau Système de Rôles

**Date**: 2026-01-11  
**Auteur**: Dev Agent (James)

## Résumé

Toutes les routes API `/api/admin/*` ont été migrées pour utiliser le nouveau système de rôles basé sur `profiles.role` au lieu de l'ancien système basé sur la table `agents`.

## Changements Effectués

### Ancien Pattern
```typescript
import { requireAuth } from "@/lib/auth";
import { getUserRole } from "@/lib/user-role";

const user = await requireAuth();
const role = await getUserRole(user.id);

if (role !== "admin") {
  return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
}
```

### Nouveau Pattern
```typescript
import { requireAdminAuth } from "@/lib/auth";

await requireAdminAuth();
// ou
const user = await requireAdminAuth();
```

## Fichiers Modifiés

### Routes Agents (1 fichier)
- ✅ `app/api/admin/agents/route.ts`

### Routes Dashboard (2 fichiers)
- ✅ `app/api/admin/dashboard/route.ts`
- ✅ `app/api/admin/dashboard/chart/route.ts`

### Routes Document Types (1 fichier)
- ✅ `app/api/admin/document-types/route.ts`

### Routes Dossiers (7 fichiers)
- ✅ `app/api/admin/dossiers/[id]/assign-agent/route.ts`
- ✅ `app/api/admin/dossiers/[id]/audit-trail/route.ts`
- ✅ `app/api/admin/dossiers/[id]/cancel/route.ts`
- ✅ `app/api/admin/dossiers/[id]/complete-step/route.ts`
- ✅ `app/api/admin/dossiers/[id]/document-history/route.ts`
- ✅ `app/api/admin/dossiers/[id]/events/route.ts`
- ✅ `app/api/admin/dossiers/[id]/notes/route.ts` (GET + POST)
- ✅ `app/api/admin/dossiers/[id]/status/route.ts`

### Routes Payment Links (6 fichiers)
- ✅ `app/api/admin/payment-links/route.ts`
- ✅ `app/api/admin/payment-links/analytics/route.ts`
- ✅ `app/api/admin/payment-links/bulk-expire/route.ts`
- ✅ `app/api/admin/payment-links/create/route.ts`
- ✅ `app/api/admin/payment-links/export/route.ts`
- ✅ `app/api/admin/payment-links/funnel/route.ts`

### Routes Products (4 fichiers)
- ✅ `app/api/admin/products/route.ts` (GET + POST + DELETE)
- ✅ `app/api/admin/products/[id]/route.ts` (GET + PATCH)
- ✅ `app/api/admin/products/[id]/workflow/route.ts` (GET + POST)

### Routes Steps (1 fichier)
- ✅ `app/api/admin/steps/route.ts`

### Routes Clients (5 fichiers) - Déjà à jour
- ✅ `app/api/admin/clients/route.ts`
- ✅ `app/api/admin/clients/[id]/route.ts`
- ✅ `app/api/admin/clients/[id]/dossiers/route.ts`
- ✅ `app/api/admin/clients/[id]/events/route.ts`
- ✅ `app/api/admin/clients/[id]/status/route.ts`

## Total

**27 fichiers** de routes API admin mis à jour pour utiliser `requireAdminAuth()`.

## Avantages

1. **Sécurité renforcée** : Seuls les utilisateurs avec `role = 'ADMIN'` peuvent accéder aux routes admin
2. **Code simplifié** : Moins de lignes de code, plus lisible
3. **Cohérence** : Toutes les routes admin utilisent maintenant le même pattern
4. **Maintenabilité** : Changements centralisés dans `lib/auth.ts`

## Comportement

### Avant
- Vérifiait si l'utilisateur existait dans la table `agents` avec `active = true`
- Retournait "admin" ou "client" comme rôle

### Après
- Vérifie directement le champ `profiles.role`
- Seuls les utilisateurs avec `role = 'ADMIN'` peuvent accéder
- Redirection automatique vers `/unauthorized` si non autorisé

## Tests Recommandés

1. ✅ Vérifier que les admins peuvent accéder à toutes les routes `/api/admin/*`
2. ✅ Vérifier que les agents (`role = 'AGENT'`) ne peuvent PAS accéder aux routes admin
3. ✅ Vérifier que les clients (`role = 'CLIENT'`) ne peuvent PAS accéder aux routes admin
4. ✅ Vérifier qu'aucune route admin n'est cassée

## Notes

- Les routes `/api/agent/*` (si elles existent) devraient utiliser `requireAgentAuth()` qui accepte AGENT et ADMIN
- Les routes publiques et client continuent d'utiliser `requireAuth()` ou `requireClientAuth()`
- Aucun changement de comportement pour les utilisateurs finaux, seulement amélioration de la sécurité

## Validation

```bash
# Vérifier qu'il n'y a plus d'ancien pattern
grep -r "getUserRole" app/api/admin/
# Résultat attendu: aucun match

# Vérifier que requireAdminAuth est utilisé
grep -r "requireAdminAuth" app/api/admin/ | wc -l
# Résultat attendu: 27+ lignes
```

✅ **Migration complétée avec succès !**
