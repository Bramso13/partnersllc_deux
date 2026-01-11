# Fix: Admin Client and Dossiers Lists Not Loading

## Problem
Les pages `/admin/clients` et `/admin/dossiers` affichaient "Aucun client/dossier trouvé" même quand des données existaient dans la base de données.

## Root Cause
Les fonctions `getAllClients()` et `getAllAdminDossiers()` utilisaient `supabase.auth.admin.listUsers()` avec la clé **anon** de Supabase, mais cette méthode nécessite la clé **service role** qui a des permissions admin.

## Solution
Utilisation de `createAdminClient()` au lieu de `createClient()` pour les appels admin API.

### Fichiers modifiés

#### 1. `partnersllc-app/lib/clients.ts`
```typescript
// Avant
import { createClient } from "@/lib/supabase/server";
const { data: authUsers } = await supabase.auth.admin.listUsers();

// Après
import { createClient, createAdminClient } from "@/lib/supabase/server";
const adminClient = createAdminClient();
const { data: authUsers } = await adminClient.auth.admin.listUsers();
```

Changements dans 2 fonctions :
- `getAllClients()` - ligne ~80
- `getClientById()` - ligne ~142

#### 2. `partnersllc-app/lib/dossiers.ts`
```typescript
// Avant
import { createClient } from "@/lib/supabase/server";
const { data: authUsers } = await supabase.auth.admin.listUsers();

// Après
import { createClient, createAdminClient } from "@/lib/supabase/server";
const adminClient = createAdminClient();
const { data: authUsers } = await adminClient.auth.admin.listUsers();
```

Changement dans 1 fonction :
- `getAllAdminDossiers()` - ligne ~493

## Configuration Required

Assurez-vous que la variable d'environnement `SUPABASE_SERVICE_ROLE_KEY` est définie dans votre fichier `.env.local` :

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key  # ← CRITICAL pour admin operations
```

La clé service role peut être trouvée dans :
- Supabase Dashboard → Settings → API → service_role key (secret)

⚠️ **ATTENTION** : Ne jamais exposer cette clé côté client ! Elle est utilisée uniquement côté serveur.

## Tested
- ✅ Page `/admin/clients` affiche maintenant tous les clients avec leurs emails
- ✅ Page `/admin/dossiers` affiche maintenant tous les dossiers avec les infos clients
- ✅ Les emails sont correctement récupérés depuis `auth.users`

## Date
2026-01-11
