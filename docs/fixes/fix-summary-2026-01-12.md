# Résumé des correctifs - 2026-01-12

Ce document résume les deux problèmes identifiés et corrigés lors de cette session.

---

## 🐛 Problème 1 : Erreur RLS sur la table `events` lors de l'upload de documents

### Symptôme
```
Version creation error: {
  code: '42501',
  message: 'new row violates row-level security policy for table "events"'
}
POST /api/workflow/upload-document 500
```

### Cause
- Un trigger PostgreSQL (`create_document_upload_event`) crée automatiquement un événement dans la table `events` lors de l'upload d'un document
- La table `events` a RLS activé mais aucune politique INSERT
- Le trigger s'exécutait avec les permissions de l'utilisateur, qui ne peut pas insérer dans `events`

### Solution
**Migration 012** : `partnersllc-app/supabase/migrations/012_fix_events_rls_policies.sql`

1. Ajout de politiques RLS complètes pour `events` :
   - Admins : accès complet
   - Agents : lecture seule
   - Clients : lecture des événements de leurs dossiers

2. Modification des fonctions trigger avec `SECURITY DEFINER` :
   - `create_dossier_status_event()`
   - `create_document_upload_event()`
   
   Cela permet aux triggers de bypass RLS pour créer des événements système.

### Documentation
- `docs/fixes/events-rls-error-on-document-upload.md`
- `debug-events-rls-policies.sql`

---

## 🐛 Problème 2 : Erreur UUID invalide lors de la création de notes de dossier

### Symptôme
```
Error creating note: {
  code: '22P02',
  message: 'invalid input syntax for type uuid: ""'
}
```

### Causes multiples
1. **Valeur vide** : `agentId=""` passé au lieu d'un UUID valide dans `page.tsx`
2. **Table obsolète** : `dossier_notes.agent_id` référençait `agents(id)`, table supprimée dans migration 009
3. **Politiques RLS obsolètes** : Référençaient la table `agents` inexistante

### Solution
**Migration 013** : `partnersllc-app/supabase/migrations/013_fix_dossier_notes_for_role_system.sql`

1. Restructuration de la table :
   - Suppression FK vers `agents`
   - Renommage `agent_id` → `user_id`
   - Nouvelle FK vers `profiles(id)`

2. Mise à jour des politiques RLS pour utiliser `auth.role()`

3. Modifications du code :
   - **API** : Utilise `user.id` de l'utilisateur authentifié au lieu du body
   - **Frontend** : Suppression du prop `agentId` de tous les composants
   - **Nettoyage** : Suppression de la chaîne de props inutiles

### Fichiers modifiés
- Migration : `013_fix_dossier_notes_for_role_system.sql`
- API : `app/api/admin/dossiers/[id]/notes/route.ts`
- Composants : 
  - `InternalNotesSection.tsx`
  - `AdminActionsSidebar.tsx`
  - `AgentAssignmentDropdown.tsx`
  - `AdminDossierDetailContent.tsx`
- Page : `app/(protected)/admin/dossiers/[id]/page.tsx`

### Documentation
- `docs/fixes/dossier-notes-invalid-uuid-error.md`
- `debug-dossier-notes.sql`

---

## 🚀 Application des correctifs

### Pour le développement local

```bash
cd partnersllc-app

# Option 1 : Reset complet (recommandé)
npx supabase db reset

# Option 2 : Push des nouvelles migrations uniquement
npx supabase db push
```

### Pour la production

Exécuter les migrations dans l'ordre via Supabase Dashboard :
1. `012_fix_events_rls_policies.sql`
2. `013_fix_dossier_notes_for_role_system.sql`

---

## ✅ Tests de validation

### Test 1 : Upload de document
1. Se connecter en tant que client
2. Accéder à un dossier avec workflow
3. Uploader un document requis
4. ✅ Vérifier que l'upload réussit sans erreur 500
5. ✅ Vérifier qu'un événement `DOCUMENT_UPLOADED` est créé

```sql
SELECT * FROM events 
WHERE entity_type = 'document' 
ORDER BY created_at DESC 
LIMIT 5;
```

### Test 2 : Création de note interne
1. Se connecter en tant qu'admin ou agent
2. Accéder à un dossier via `/admin/dossiers/[id]`
3. Ajouter une note interne dans la sidebar
4. ✅ Vérifier que la note est créée sans erreur
5. ✅ Vérifier que le nom de l'utilisateur s'affiche

```sql
SELECT 
  n.*,
  p.full_name,
  p.role
FROM dossier_notes n
INNER JOIN profiles p ON n.user_id = p.id
ORDER BY n.created_at DESC
LIMIT 5;
```

---

## 🎯 Impact et bénéfices

### Sécurité
- ✅ Politiques RLS complètes et cohérentes
- ✅ Pas de spoofing d'identité possible (user_id extrait du token)
- ✅ Triggers système correctement isolés avec SECURITY DEFINER

### Architecture
- ✅ Cohérence du système de rôles (utilisation de `profiles.role` partout)
- ✅ Simplification du code (suppression des props inutiles)
- ✅ Meilleure nomenclature (`user_id` au lieu de `agent_id`)

### Maintenance
- ✅ Code plus simple et maintenable
- ✅ Documentation complète des correctifs
- ✅ Scripts SQL de diagnostic pour le troubleshooting

---

## 📚 Ressources

### Migrations
- `partnersllc-app/supabase/migrations/012_fix_events_rls_policies.sql`
- `partnersllc-app/supabase/migrations/013_fix_dossier_notes_for_role_system.sql`

### Documentation
- `docs/fixes/events-rls-error-on-document-upload.md`
- `docs/fixes/dossier-notes-invalid-uuid-error.md`
- `docs/fixes/fix-summary-2026-01-12.md` (ce fichier)

### Scripts de diagnostic
- `debug-events-rls-policies.sql`
- `debug-dossier-notes.sql`

### Références PostgreSQL/Supabase
- [PostgreSQL Security Definer Functions](https://www.postgresql.org/docs/current/sql-createfunction.html)
- [Supabase Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/trigger-definition.html)

---

## 🔄 Prochaines étapes recommandées

1. **Appliquer les migrations** en développement et tester
2. **Exécuter les scripts de diagnostic** pour valider l'état de la base
3. **Tester les deux fonctionnalités** (upload + notes) de bout en bout
4. **Planifier le déploiement en production** :
   - Backup de la base avant migration
   - Exécution des migrations en maintenance window
   - Validation post-déploiement

---

**Date** : 2026-01-12  
**Auteur** : Dev Agent  
**Status** : ✅ Correctifs implémentés et documentés
