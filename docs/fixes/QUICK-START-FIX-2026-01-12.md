# Guide rapide : Application des correctifs du 2026-01-12

## 🎯 Résumé en 30 secondes

Deux correctifs critiques ont été développés :
1. **Upload de documents** : Erreur RLS sur table `events` → Migration 012
2. **Notes internes** : UUID invalide + table obsolète → Migration 013

## 🚀 Application rapide (Développement)

```bash
# Étape 1 : Aller dans le dossier de l'app
cd partnersllc-app

# Étape 2 : Reset complet de la base (recommandé)
npx supabase db reset

# Étape 3 : Vérifier que tout fonctionne
# - Tester l'upload d'un document
# - Tester la création d'une note interne

# Étape 4 (optionnel) : Exécuter les diagnostics
npx supabase db execute -f ../debug-events-rls-policies.sql
npx supabase db execute -f ../debug-dossier-notes.sql
```

## 📋 Checklist de validation

### Test 1 : Upload de document ✅
```
1. Se connecter en tant que CLIENT
2. Aller dans un dossier avec workflow
3. Uploader un document requis
4. Vérifier : pas d'erreur 500
5. Vérifier : événement créé dans la table events
```

### Test 2 : Création de note ✅
```
1. Se connecter en tant qu'ADMIN ou AGENT
2. Aller dans /admin/dossiers/[un-id-de-dossier]
3. Ajouter une note interne dans la sidebar
4. Vérifier : pas d'erreur
5. Vérifier : nom de l'utilisateur affiché
```

## 📊 Vérification SQL rapide

```sql
-- Vérifier les événements récents
SELECT event_type, entity_type, created_at 
FROM events 
ORDER BY created_at DESC 
LIMIT 5;

-- Vérifier les notes récentes
SELECT n.note_text, p.full_name, n.created_at
FROM dossier_notes n
INNER JOIN profiles p ON n.user_id = p.id
ORDER BY n.created_at DESC
LIMIT 5;
```

## 🆘 En cas de problème

### Erreur lors de la migration
```bash
# Vérifier les migrations appliquées
npx supabase migration list

# Forcer l'application d'une migration spécifique
npx supabase db push --include-all
```

### Erreur "agents table does not exist"
→ La migration 013 n'a pas été appliquée
→ Exécuter : `npx supabase db reset`

### Erreur RLS persist après migration
→ Vérifier que les politiques sont bien créées :
```sql
SELECT policyname FROM pg_policies WHERE tablename = 'events';
SELECT policyname FROM pg_policies WHERE tablename = 'dossier_notes';
```

## 📚 Documentation complète

Pour plus de détails, consultez :
- `docs/fixes/events-rls-error-on-document-upload.md`
- `docs/fixes/dossier-notes-invalid-uuid-error.md`
- `docs/fixes/fix-summary-2026-01-12.md`
- `docs/fixes/CHANGELOG-2026-01-12.md`

## 🏭 Déploiement en production

**⚠️ IMPORTANT** : Faire un backup avant !

```bash
# 1. Backup de la base
npx supabase db dump -f backup-before-fix.sql

# 2. Appliquer les migrations
npx supabase db push

# 3. Valider avec les tests ci-dessus

# 4. Si problème, rollback
npx supabase db reset --db-url <your-production-url>
```

## 🎉 Terminé !

Si les deux tests passent, les correctifs sont appliqués avec succès.

---

**Besoin d'aide ?** Consultez la documentation complète dans `docs/fixes/`
