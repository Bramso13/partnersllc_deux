# Addendum : Correction supplémentaire - Colonne email inexistante

## 🐛 Problème supplémentaire découvert

Après l'implémentation de la migration 013, une erreur supplémentaire est apparue :

```
Error fetching notes: {
  code: '42703',
  message: 'column profiles_1.email does not exist'
}
```

## 🔍 Cause

L'API tentait de sélectionner la colonne `email` de la table `profiles`, mais cette colonne n'existe pas.

### Structure de la table `profiles`

```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  phone text,
  status user_status DEFAULT 'PENDING' NOT NULL,
  stripe_customer_id text UNIQUE,
  role user_role NOT NULL DEFAULT 'CLIENT',  -- Ajouté par migration 008
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);
```

**Points importants** :
- ✅ `profiles` contient `full_name`
- ❌ `profiles` ne contient **PAS** `email`
- ℹ️ L'email est stocké dans la table système `auth.users`

## ✅ Solution

### Correction de l'API

**Fichier** : `app/api/admin/dossiers/[id]/notes/route.ts`

#### Avant (incorrect)
```typescript
.select(`
  id,
  dossier_id,
  user_id,
  note_text,
  created_at,
  updated_at,
  user:user_id (
    full_name,
    email      // ❌ N'existe pas dans profiles
  )
`)
```

#### Après (correct)
```typescript
.select(`
  id,
  dossier_id,
  user_id,
  note_text,
  created_at,
  updated_at,
  user:user_id (
    full_name  // ✅ Seulement full_name
  )
`)
```

### Transformation de la réponse

```typescript
// Avant
user_name: note.user?.full_name || note.user?.email || "Utilisateur inconnu"

// Après
user_name: note.user?.full_name || "Utilisateur inconnu"
```

## 📝 Fichiers modifiés

1. `partnersllc-app/app/api/admin/dossiers/[id]/notes/route.ts` (GET et POST)
2. `debug-dossier-notes.sql` (retrait des références à email)
3. `docs/fixes/dossier-notes-invalid-uuid-error.md` (mise à jour documentation)
4. `docs/fixes/CHANGELOG-2026-01-12.md` (ajout de la note)
5. `docs/fixes/fix-summary-2026-01-12.md` (ajout de la note)
6. `docs/fixes/ADDENDUM-email-column-fix.md` (ce fichier)

## 🔧 Alternative : Afficher l'email

Si vous souhaitez afficher l'email des utilisateurs, vous devrez faire une jointure avec `auth.users` :

### Option 1 : Via SQL brut

```typescript
const { data: notes } = await supabase.rpc('get_dossier_notes_with_email', {
  p_dossier_id: dossierId
});
```

Avec une fonction PostgreSQL :
```sql
CREATE OR REPLACE FUNCTION get_dossier_notes_with_email(p_dossier_id uuid)
RETURNS TABLE (
  id uuid,
  note_text text,
  created_at timestamptz,
  user_name text,
  user_email text
) AS $$
  SELECT 
    dn.id,
    dn.note_text,
    dn.created_at,
    p.full_name as user_name,
    au.email as user_email
  FROM dossier_notes dn
  INNER JOIN profiles p ON dn.user_id = p.id
  INNER JOIN auth.users au ON p.id = au.id
  WHERE dn.dossier_id = p_dossier_id
  ORDER BY dn.created_at DESC;
$$ LANGUAGE SQL SECURITY DEFINER;
```

### Option 2 : Ajouter email à profiles (migration)

Si l'email est fréquemment utilisé, vous pourriez le dupliquer dans `profiles` :

```sql
-- Migration: add_email_to_profiles.sql
ALTER TABLE profiles ADD COLUMN email text;

-- Copier les emails depuis auth.users
UPDATE profiles p
SET email = au.email
FROM auth.users au
WHERE p.id = au.id;

-- Trigger pour synchroniser automatiquement
CREATE OR REPLACE FUNCTION sync_profile_email()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET email = NEW.email
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER sync_email_on_user_update
AFTER UPDATE OF email ON auth.users
FOR EACH ROW
EXECUTE FUNCTION sync_profile_email();
```

**⚠️ Attention** : Cette approche introduit de la duplication de données et nécessite une synchronisation continue.

## 💡 Recommandation

Pour l'instant, **afficher uniquement `full_name`** est suffisant. Les notes internes sont principalement pour le suivi, pas pour l'identification précise. Si `full_name` est vide, "Utilisateur inconnu" s'affiche.

Si l'email devient nécessaire plus tard, privilégier l'**Option 1** (fonction SQL) pour éviter la duplication de données.

## ✅ Tests de validation

Après cette correction :

```bash
# Test GET
curl http://localhost:3000/api/admin/dossiers/[dossier-id]/notes

# Devrait retourner :
{
  "id": "...",
  "note_text": "Test note",
  "user_name": "John Doe",  // ou "Utilisateur inconnu"
  "created_at": "..."
}
```

---

**Date** : 2026-01-12  
**Auteur** : Dev Agent  
**Status** : ✅ Corrigé
