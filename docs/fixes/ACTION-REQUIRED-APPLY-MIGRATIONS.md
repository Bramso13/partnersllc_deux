# 🚨 ACTION REQUISE : Appliquer les migrations

## ⚠️ État actuel

Les correctifs ont été implémentés dans le code, mais **les migrations de base de données n'ont pas encore été appliquées**.

**Symptômes actuels** :
- ❌ Upload de documents : Erreur RLS sur table `events`
- ❌ Création de notes : Erreur RLS sur table `dossier_notes`

## ✅ Solution : Appliquer les migrations

### Option 1 : Reset complet (RECOMMANDÉ pour développement)

```bash
cd partnersllc-app
npx supabase db reset
```

Cette commande va :
1. Supprimer toutes les données existantes
2. Recréer la base de données from scratch
3. Appliquer toutes les migrations (001 → 013)
4. Appliquer les seeds

**⚠️ ATTENTION** : Toutes les données seront perdues !

### Option 2 : Push des nouvelles migrations uniquement

```bash
cd partnersllc-app
npx supabase db push
```

Cette commande va :
1. Détecter les migrations non appliquées (012, 013)
2. Les appliquer dans l'ordre
3. Préserver les données existantes

**Recommandé pour** : Production ou si vous avez des données à conserver

### Option 3 : Application manuelle

Si vous avez des problèmes avec npx/npm, vous pouvez appliquer les migrations manuellement via le Dashboard Supabase :

1. Ouvrir Supabase Dashboard
2. Aller dans SQL Editor
3. Copier/coller le contenu de chaque migration :
   - `partnersllc-app/supabase/migrations/012_fix_events_rls_policies.sql`
   - `partnersllc-app/supabase/migrations/013_fix_dossier_notes_for_role_system.sql`
4. Exécuter chaque migration dans l'ordre

## 🔍 Vérification après migration

### Test 1 : Vérifier que les migrations sont appliquées

```bash
cd partnersllc-app
npx supabase migration list
```

Vous devriez voir :
```
✓ 001_...
✓ 002_...
...
✓ 012_fix_events_rls_policies
✓ 013_fix_dossier_notes_for_role_system
```

### Test 2 : Vérifier les politiques RLS

Via SQL Editor :

```sql
-- Vérifier les politiques sur events
SELECT policyname FROM pg_policies WHERE tablename = 'events';
-- Devrait retourner 3 politiques (Admins, Agents, Clients)

-- Vérifier les politiques sur dossier_notes
SELECT policyname FROM pg_policies WHERE tablename = 'dossier_notes';
-- Devrait retourner 5 politiques

-- Vérifier la structure de dossier_notes
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'dossier_notes';
-- Devrait contenir 'user_id' (pas 'agent_id')
```

### Test 3 : Fonctionnalités

1. **Upload de document** :
   - Se connecter en tant que CLIENT
   - Aller dans un dossier avec workflow
   - Uploader un document
   - ✅ Devrait réussir sans erreur 500

2. **Création de note** :
   - Se connecter en tant qu'ADMIN/AGENT
   - Aller dans `/admin/dossiers/[id]`
   - Ajouter une note interne
   - ✅ Devrait réussir sans erreur 500

## 🆘 Problèmes courants

### Erreur npm permissions

Si vous voyez :
```
npm error errno EPERM
npm error Your cache folder contains root-owned files
```

**Solution** :
```bash
sudo chown -R $(whoami) ~/.npm
```

Puis réessayer la commande.

### Erreur "migration already applied"

Si migration 012 ou 013 existe déjà dans votre base :
```bash
cd partnersllc-app
npx supabase db reset  # Forcer reset complet
```

### Base de données locale vs production

**Important** : Ces commandes s'appliquent à votre base locale Supabase par défaut.

Pour appliquer en production :
```bash
npx supabase link --project-ref <your-project-ref>
npx supabase db push
```

## 📊 État attendu après migration

```
✅ Table events : Politiques RLS complètes
✅ Triggers events : SECURITY DEFINER appliqué
✅ Table dossier_notes : Colonne user_id (pas agent_id)
✅ Table dossier_notes : FK vers profiles (pas agents)
✅ Table dossier_notes : Politiques RLS pour ADMIN/AGENT/CLIENT
✅ Upload documents : Fonctionnel
✅ Création notes : Fonctionnel
```

## 🚀 Prêt ?

Exécutez maintenant :

```bash
cd partnersllc-app
npx supabase db reset
```

Puis testez les deux fonctionnalités ! 🎉

---

**Besoin d'aide ?** Consultez les guides détaillés :
- `docs/fixes/QUICK-START-FIX-2026-01-12.md`
- `docs/fixes/fix-summary-2026-01-12.md`
