# Changelog des correctifs - 2026-01-12

## Nouveaux fichiers créés

### Migrations
1. `partnersllc-app/supabase/migrations/012_fix_events_rls_policies.sql`
   - Ajoute les politiques RLS manquantes pour la table `events`
   - Modifie les fonctions trigger pour utiliser `SECURITY DEFINER`

2. `partnersllc-app/supabase/migrations/013_fix_dossier_notes_for_role_system.sql`
   - Renomme `agent_id` → `user_id` dans `dossier_notes`
   - Met à jour la FK pour référencer `profiles` au lieu de `agents`
   - Remplace les politiques RLS pour utiliser le nouveau système de rôles

### Documentation
3. `docs/fixes/events-rls-error-on-document-upload.md`
   - Explication détaillée du problème RLS sur la table `events`
   - Guide de résolution et migration

4. `docs/fixes/dossier-notes-invalid-uuid-error.md`
   - Explication détaillée du problème UUID invalide
   - Guide complet de la correction

5. `docs/fixes/fix-summary-2026-01-12.md`
   - Résumé global des deux correctifs
   - Guide de test et déploiement

### Scripts de diagnostic
6. `debug-events-rls-policies.sql`
   - Script SQL pour diagnostiquer les politiques RLS sur `events`
   - Vérification des triggers et leur sécurité

7. `debug-dossier-notes.sql`
   - Script SQL pour diagnostiquer la table `dossier_notes`
   - Vérification des contraintes et données

8. `docs/fixes/CHANGELOG-2026-01-12.md`
   - Ce fichier - liste complète des changements

---

## Fichiers modifiés

### Backend - API Routes

#### `partnersllc-app/app/api/admin/dossiers/[id]/notes/route.ts`
**Changements** :
- ✅ GET : Remplacé `agents:agent_id` par `user:user_id` dans le SELECT
- ✅ GET : Retiré `email` du SELECT (n'existe pas dans profiles)
- ✅ GET : Transformé `agent_name` → `user_name` dans la réponse
- ✅ POST : Supprimé le paramètre `agentId` du body
- ✅ POST : Utilise `user.id` de l'utilisateur authentifié
- ✅ POST : Remplacé `agent_id` par `user_id` dans l'insert
- ✅ POST : Remplacé référence `agents:agent_id` par `user:user_id`
- ✅ POST : Retiré `email` du SELECT (n'existe pas dans profiles)

### Backend - Pages

#### `partnersllc-app/app/(protected)/admin/dossiers/[id]/page.tsx`
**Changements** :
- ✅ Supprimé le prop `agentId=""` passé à `AdminDossierDetailContent`
- ✅ Simplifié : ne capture plus le résultat de `requireAdminAuth()`

#### `partnersllc-app/app/(protected)/admin/dossiers/[id]/AdminDossierDetailContent.tsx`
**Changements** :
- ✅ Supprimé `agentId` de l'interface `AdminDossierDetailContentProps`
- ✅ Supprimé le prop `agentId` passé à `AdminActionsSidebar`

### Frontend - Composants

#### `partnersllc-app/components/admin/dossier/InternalNotesSection.tsx`
**Changements** :
- ✅ Interface `InternalNote` : `agent_id` → `user_id`, `agent_name` → `user_name`
- ✅ Supprimé `agentId` de `InternalNotesSectionProps`
- ✅ Supprimé `agentId` du body de la requête POST
- ✅ Affichage : `note.agent_name` → `note.user_name`

#### `partnersllc-app/components/admin/dossier/AdminActionsSidebar.tsx`
**Changements** :
- ✅ Supprimé `agentId` de l'interface `AdminActionsSidebarProps`
- ✅ Supprimé le prop `agentId` passé à `AgentAssignmentDropdown`
- ✅ Supprimé le prop `agentId` passé à `InternalNotesSection`

#### `partnersllc-app/components/admin/dossier/AgentAssignmentDropdown.tsx`
**Changements** :
- ✅ Supprimé `agentId` de `AgentAssignmentDropdownProps` (n'était pas utilisé)

---

## Résumé des changements par type

### Base de données
- 2 nouvelles migrations créées
- 1 table restructurée (`dossier_notes`)
- 6 politiques RLS créées/mises à jour (`events`)
- 5 politiques RLS créées/mises à jour (`dossier_notes`)
- 2 fonctions trigger modifiées (`SECURITY DEFINER` ajouté)

### Code Backend
- 1 API route modifiée (`notes/route.ts`)
- 2 pages modifiées

### Code Frontend
- 3 composants modifiés

### Documentation
- 5 nouveaux fichiers de documentation
- 2 scripts SQL de diagnostic

---

## Impact sur les fonctionnalités

### ✅ Fonctionnalités corrigées
1. **Upload de documents** : Fonctionne maintenant sans erreur RLS
2. **Création de notes internes** : Fonctionne avec l'ID utilisateur correct

### ⚠️ Changements breaking (migrations requises)
- Migration 012 doit être appliquée pour que l'upload de documents fonctionne
- Migration 013 doit être appliquée pour que les notes fonctionnent

### 🔄 Modifications de schéma
- `dossier_notes.agent_id` → `dossier_notes.user_id` (renommage de colonne)
- FK `dossier_notes` : `agents(id)` → `profiles(id)` (nouvelle référence)

---

## Compatibilité et migration des données

### Migration 012 (`events`)
- ✅ Pas de changement de schéma
- ✅ Pas de migration de données nécessaire
- ✅ Rétrocompatible

### Migration 013 (`dossier_notes`)
- ⚠️ Changement de schéma (renommage de colonne)
- ✅ Données préservées (renommage, pas de transformation)
- ✅ Compatible si migration 009 a été appliquée correctement
- ℹ️ Les IDs dans l'ancienne colonne `agent_id` doivent déjà pointer vers `profiles.id`

---

## Actions requises pour le déploiement

### Développement
```bash
cd partnersllc-app
npx supabase db reset  # Recommandé
# OU
npx supabase db push   # Si vous voulez préserver les données
```

### Production
1. **Backup de la base de données**
2. **Exécuter migration 012** via Supabase Dashboard
3. **Tester l'upload de documents**
4. **Exécuter migration 013** via Supabase Dashboard
5. **Tester la création de notes**
6. **Exécuter les scripts de diagnostic** pour valider

---

## Checklist de validation

### Après migration 012
- [ ] Upload de document réussit sans erreur 500
- [ ] Événements `DOCUMENT_UPLOADED` créés dans la table `events`
- [ ] Événements visibles pour les admins/agents
- [ ] Événements visibles pour les clients (leurs dossiers uniquement)

### Après migration 013
- [ ] Création de note réussit sans erreur
- [ ] Nom de l'utilisateur s'affiche correctement
- [ ] Notes visibles pour tous les admins/agents
- [ ] Notes NON visibles pour les clients

### Validation globale
- [ ] Pas d'erreurs dans les logs du serveur
- [ ] Pas d'erreurs dans la console du navigateur
- [ ] Scripts de diagnostic exécutés avec succès
- [ ] Politiques RLS appliquées correctement

---

## Notes pour l'équipe

### Leçons apprises
1. **Triggers et RLS** : Les triggers doivent utiliser `SECURITY DEFINER` pour créer des données système
2. **Migration de schéma** : Bien vérifier les dépendances entre tables lors de refactorings
3. **Propagation de props** : Éviter de passer des props inutiles dans la chaîne de composants

### Bonnes pratiques appliquées
1. ✅ Documentation complète pour chaque correctif
2. ✅ Scripts SQL de diagnostic pour le troubleshooting
3. ✅ Politiques RLS granulaires par rôle
4. ✅ Utilisation de `SECURITY DEFINER` pour les opérations système
5. ✅ Nomenclature cohérente (`user_id` au lieu de `agent_id`)

---

**Date de création** : 2026-01-12  
**Dernière mise à jour** : 2026-01-12  
**Auteur** : Dev Agent  
**Version** : 1.0
