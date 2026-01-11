# Fix: Erreur RLS sur la table `events` lors de l'upload de documents

## 🐛 Problème identifié

Lors de l'upload d'un document via l'API `/api/workflow/upload-document`, l'erreur suivante se produit :

```
Version creation error: {
  code: '42501',
  details: null,
  hint: null,
  message: 'new row violates row-level security policy for table "events"'
}
POST /api/workflow/upload-document 500
```

## 🔍 Cause racine

1. **Trigger automatique** : Lorsqu'une nouvelle version de document est insérée dans `document_versions`, un trigger PostgreSQL (`create_document_upload_event`) s'exécute automatiquement pour créer un événement dans la table `events` (voir `database-v2.sql` lignes 896-924).

2. **RLS activé sans politique INSERT** : La table `events` a Row-Level Security (RLS) activé, mais il n'existe **aucune politique INSERT**. Il n'y a qu'une politique SELECT pour que les utilisateurs puissent voir les événements de leurs dossiers.

3. **Contexte d'exécution du trigger** : Par défaut, les fonctions de trigger s'exécutent avec les permissions de l'utilisateur qui a déclenché l'opération. Puisqu'il n'y a pas de politique INSERT autorisant les clients à insérer des événements, l'insertion échoue.

## ✅ Solution

La migration `012_fix_events_rls_policies.sql` a été créée avec deux correctifs :

### 1. Ajout des politiques RLS pour la table `events`

```sql
-- Admins ont un accès complet
CREATE POLICY "Admins have full access to events"
  ON events FOR ALL
  USING (auth.role() = 'ADMIN')
  WITH CHECK (auth.role() = 'ADMIN');

-- Agents peuvent voir tous les événements
CREATE POLICY "Agents can view all events"
  ON events FOR SELECT
  USING (auth.role() IN ('AGENT', 'ADMIN'));

-- Clients peuvent voir les événements de leurs dossiers
CREATE POLICY "Clients can view events for their dossiers"
  ON events FOR SELECT
  USING (
    auth.role() = 'CLIENT' AND
    (
      (entity_type = 'dossier' AND entity_id::uuid IN (
        SELECT id FROM dossiers WHERE user_id = auth.uid()
      ))
      OR
      (entity_type = 'document' AND entity_id::uuid IN (
        SELECT d.id FROM documents d
        INNER JOIN dossiers dos ON d.dossier_id = dos.id
        WHERE dos.user_id = auth.uid()
      ))
    )
  );
```

### 2. Modification des fonctions trigger avec `SECURITY DEFINER`

Les fonctions `create_dossier_status_event()` et `create_document_upload_event()` ont été recréées avec l'option **`SECURITY DEFINER`** :

```sql
CREATE OR REPLACE FUNCTION create_document_upload_event()
RETURNS TRIGGER
SECURITY DEFINER -- Permet de bypass RLS
SET search_path = public
AS $$
-- ... code de la fonction ...
$$ LANGUAGE plpgsql;
```

**Pourquoi `SECURITY DEFINER` ?**
- Avec `SECURITY DEFINER`, la fonction s'exécute avec les permissions du propriétaire de la fonction (généralement le super-utilisateur ou le propriétaire du schéma), pas avec les permissions de l'utilisateur qui a déclenché le trigger
- Cela permet au trigger d'insérer des événements même si l'utilisateur n'a pas de politique INSERT explicite
- C'est une pratique standard pour les triggers qui doivent effectuer des opérations système/audit

## 📝 Étapes pour appliquer le correctif

### Option 1 : Reset complet de la base de données (développement uniquement)

```bash
cd partnersllc-app
npx supabase db reset
```

Cette commande va :
- Recréer toute la base de données
- Appliquer toutes les migrations dans l'ordre (001 à 012)
- Appliquer les seeds

### Option 2 : Appliquer uniquement la nouvelle migration

```bash
cd partnersllc-app
npx supabase db push
```

Cette commande va appliquer uniquement les migrations qui n'ont pas encore été appliquées.

### Option 3 : Exécution manuelle SQL (production)

Si vous êtes en production, vous pouvez exécuter le contenu de `012_fix_events_rls_policies.sql` directement via :

```bash
npx supabase db remote commit
```

Ou via l'interface Supabase Dashboard → SQL Editor.

## 🧪 Test après correction

Après avoir appliqué la migration, testez à nouveau l'upload d'un document :

1. Connectez-vous en tant que client
2. Accédez à un dossier
3. Uploadez un document
4. Vérifiez que l'upload réussit sans erreur 500
5. Vérifiez que l'événement a bien été créé dans la table `events`

```sql
-- Vérifier les événements créés
SELECT * FROM events 
WHERE entity_type = 'document' 
ORDER BY created_at DESC 
LIMIT 5;
```

## 📚 Références

- **Fichier de migration** : `partnersllc-app/supabase/migrations/012_fix_events_rls_policies.sql`
- **Code source du trigger** : `partnersllc-app/database-v2.sql` lignes 896-924
- **Route API affectée** : `partnersllc-app/app/api/workflow/upload-document/route.ts`
- **Documentation PostgreSQL** : [SECURITY DEFINER](https://www.postgresql.org/docs/current/sql-createfunction.html)
- **Documentation Supabase** : [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

## 💡 Points importants

1. **Sécurité** : L'utilisation de `SECURITY DEFINER` doit être faite avec précaution. Dans ce cas, c'est approprié car :
   - Les triggers créent des événements d'audit système
   - Les données insérées sont dérivées de l'opération en cours (pas de données utilisateur arbitraires)
   - Les politiques SELECT empêchent les utilisateurs de voir des événements non autorisés

2. **Alternative non recommandée** : Désactiver RLS sur la table `events` (`ALTER TABLE events DISABLE ROW LEVEL SECURITY`) aurait aussi fonctionné, mais aurait exposé tous les événements à tous les utilisateurs - ce qui est un problème de sécurité.

3. **Pourquoi pas une politique INSERT ?** : Permettre aux utilisateurs d'insérer directement dans `events` serait une faille de sécurité. Les événements doivent être créés uniquement par le système (via triggers) pour garantir l'intégrité de l'audit trail.
