# Fix: Erreur UUID invalide lors de la création de notes de dossier

## 🐛 Problème identifié

Lors de la tentative de création d'une note interne sur un dossier via la page admin, l'erreur suivante se produit :

```
Error creating note: {
  code: '22P02',
  details: null,
  hint: null,
  message: 'invalid input syntax for type uuid: ""'
}
```

## 🔍 Cause racine

Le problème avait plusieurs sources interconnectées :

### 1. **Valeur vide passée pour `agentId`**

Dans le fichier `app/(protected)/admin/dossiers/[id]/page.tsx` ligne 48 :

```typescript
<AdminDossierDetailContent
  dossier={dossier}
  productSteps={productSteps}
  agentId=""  // ❌ Chaîne vide au lieu d'un UUID valide
/>
```

Cette chaîne vide était propagée jusqu'à l'API qui tentait de l'insérer dans la colonne `agent_id` (type UUID), causant l'erreur.

### 2. **Référence obsolète à la table `agents`**

La table `dossier_notes` a été créée avec la migration `005_dossier_notes_table.sql` qui référençait :

```sql
agent_id uuid NOT NULL REFERENCES agents(id) ON DELETE RESTRICT
```

**Problème** : La migration `009_update_rls_policies_for_roles.sql` a supprimé la table `agents` et l'a remplacée par un système de rôles dans la table `profiles`. La colonne `agent_id` pointait donc vers une table inexistante.

### 3. **Politiques RLS obsolètes**

Les politiques RLS de la table `dossier_notes` référençaient la table `agents` qui n'existait plus :

```sql
CREATE POLICY "Agents can view all dossier notes"
  ON dossier_notes FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM agents WHERE agents.id = auth.uid())
  );
```

## ✅ Solution

### 1. **Migration 013** : Mise à jour de la table `dossier_notes`

Fichier : `partnersllc-app/supabase/migrations/013_fix_dossier_notes_for_role_system.sql`

Cette migration effectue les changements suivants :

#### a) Restructuration de la table

```sql
-- Supprimer l'ancienne contrainte de clé étrangère vers agents
ALTER TABLE dossier_notes 
  DROP CONSTRAINT IF EXISTS dossier_notes_agent_id_fkey;

-- Renommer agent_id en user_id pour clarté
ALTER TABLE dossier_notes 
  RENAME COLUMN agent_id TO user_id;

-- Ajouter nouvelle contrainte vers profiles
ALTER TABLE dossier_notes 
  ADD CONSTRAINT dossier_notes_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES profiles(id) 
  ON DELETE RESTRICT;
```

#### b) Mise à jour des politiques RLS

```sql
-- Admins ont un accès complet
CREATE POLICY "Admins have full access to dossier notes"
  ON dossier_notes FOR ALL
  USING (auth.role() = 'ADMIN')
  WITH CHECK (auth.role() = 'ADMIN');

-- Agents peuvent voir toutes les notes
CREATE POLICY "Agents can view all dossier notes"
  ON dossier_notes FOR SELECT
  USING (auth.role() IN ('AGENT', 'ADMIN'));

-- Agents/admins peuvent créer des notes (assignées à eux-mêmes)
CREATE POLICY "Agents and admins can create dossier notes"
  ON dossier_notes FOR INSERT
  WITH CHECK (
    auth.role() IN ('AGENT', 'ADMIN')
    AND user_id = auth.uid()
  );

-- Les utilisateurs peuvent modifier/supprimer leurs propres notes
CREATE POLICY "Users can update their own notes"
  ON dossier_notes FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

### 2. **Mise à jour de l'API** : `app/api/admin/dossiers/[id]/notes/route.ts`

#### GET - Lecture des notes

```typescript
const { data: notes } = await supabase
  .from("dossier_notes")
  .select(`
    id,
    dossier_id,
    user_id,
    note_text,
    created_at,
    updated_at,
    user:user_id (
      full_name
    )
  `)
  .eq("dossier_id", dossierId)
  .order("created_at", { ascending: false });
```

**Note importante** : La table `profiles` ne contient que `full_name`, pas `email`. L'email est stocké dans `auth.users`.

#### POST - Création de note

```typescript
export async function POST(request: NextRequest, { params }) {
  const user = await requireAdminAuth();
  const { noteText } = await request.json();
  
  // user_id est automatiquement l'utilisateur authentifié
  const { data: note } = await supabase
    .from("dossier_notes")
    .insert({
      dossier_id: dossierId,
      user_id: user.id,  // ✅ ID de l'utilisateur authentifié
      note_text: noteText.trim(),
    })
    .select(`
      id,
      dossier_id,
      user_id,
      note_text,
      created_at,
      updated_at,
      user:user_id (
        full_name
      )
    `)
    .single();
    
  return NextResponse.json(note);
}
```

**Changements clés** :
- ✅ Suppression du paramètre `agentId` du body
- ✅ Utilisation de `user.id` de l'utilisateur authentifié
- ✅ Référence à `profiles` via la relation `user:user_id`
- ✅ Sélection uniquement de `full_name` (pas d'email dans profiles)

### 3. **Mise à jour du composant frontend** : `InternalNotesSection.tsx`

#### a) Simplification de l'interface

```typescript
interface InternalNote {
  id: string;
  note_text: string;
  created_at: string;
  user_id: string;        // ✅ Renommé de agent_id
  user_name?: string;      // ✅ Renommé de agent_name
}

interface InternalNotesSectionProps {
  dossierId: string;
  // ❌ agentId supprimé - non nécessaire
}
```

#### b) Suppression de `agentId` du body

```typescript
const handleAddNote = async () => {
  const response = await fetch(`/api/admin/dossiers/${dossierId}/notes`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      noteText: newNote.trim(),
      // ❌ agentId supprimé
    }),
  });
};
```

### 4. **Nettoyage de la chaîne de composants**

Suppression du prop `agentId` qui n'était plus utilisé :

- ✅ `AdminDossierDetailContent.tsx` - Suppression du prop
- ✅ `AdminActionsSidebar.tsx` - Suppression du prop
- ✅ `AgentAssignmentDropdown.tsx` - Suppression du prop inutilisé
- ✅ `app/(protected)/admin/dossiers/[id]/page.tsx` - Suppression de la propagation

## 📝 Étapes pour appliquer le correctif

### Option 1 : Reset complet (développement)

```bash
cd partnersllc-app
npx supabase db reset
```

### Option 2 : Appliquer uniquement les nouvelles migrations

```bash
cd partnersllc-app
npx supabase db push
```

### Option 3 : Exécution manuelle (production)

Exécuter le contenu de `013_fix_dossier_notes_for_role_system.sql` via Supabase Dashboard.

## 🧪 Test après correction

1. Se connecter en tant qu'admin ou agent
2. Accéder à un dossier via `/admin/dossiers/[id]`
3. Dans la section "Notes internes" de la sidebar droite :
   - Taper une note
   - Cliquer sur "Ajouter une note"
4. Vérifier que la note est créée sans erreur
5. Vérifier que le nom de l'utilisateur s'affiche correctement

```sql
-- Vérifier les notes créées
SELECT 
  n.*,
  p.full_name,
  p.role
FROM dossier_notes n
INNER JOIN profiles p ON n.user_id = p.id
ORDER BY n.created_at DESC
LIMIT 5;
```

**Note** : L'email des utilisateurs n'est pas dans `profiles`, mais dans `auth.users`. Si vous avez besoin de l'email, vous devrez faire une jointure supplémentaire.

## 💡 Points importants

### Sécurité

1. **Authentification obligatoire** : L'API utilise `requireAdminAuth()` qui garantit que seuls les admins/agents peuvent créer des notes
2. **Pas de spoofing d'identité** : Le `user_id` est extrait du token d'authentification, pas du body de la requête
3. **RLS appliqué** : Les politiques garantissent que seuls les admins/agents voient les notes

### Architecture

1. **Cohérence des rôles** : Le système utilise maintenant de manière cohérente `profiles.role` au lieu d'une table `agents` séparée
2. **Nomenclature claire** : `user_id` au lieu de `agent_id` reflète mieux la réalité (peut être un admin ou un agent)
3. **Simplicité** : Suppression des props inutiles dans la chaîne de composants

### Migration de données

Si des notes existaient déjà dans la base :
- La colonne `agent_id` est renommée en `user_id` (données préservées)
- Les IDs référençaient déjà des utilisateurs dans `profiles` (si migration 009 appliquée correctement)
- Aucune transformation de données nécessaire

## 📚 Fichiers modifiés

### Migrations
- `partnersllc-app/supabase/migrations/013_fix_dossier_notes_for_role_system.sql` (nouveau)

### Backend
- `partnersllc-app/app/api/admin/dossiers/[id]/notes/route.ts`
- `partnersllc-app/app/(protected)/admin/dossiers/[id]/page.tsx`

### Frontend
- `partnersllc-app/components/admin/dossier/InternalNotesSection.tsx`
- `partnersllc-app/components/admin/dossier/AdminActionsSidebar.tsx`
- `partnersllc-app/components/admin/dossier/AgentAssignmentDropdown.tsx`
- `partnersllc-app/app/(protected)/admin/dossiers/[id]/AdminDossierDetailContent.tsx`

### Documentation
- `docs/fixes/dossier-notes-invalid-uuid-error.md` (ce fichier)
