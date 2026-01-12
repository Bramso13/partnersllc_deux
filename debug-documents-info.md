# Debug : Documents ne s'affichent pas dans la validation

## Logs ajoutés

### 1. Logs côté serveur (API)
Fichier : `partnersllc-app/app/api/admin/dossiers/[id]/validation/route.ts`

Les logs suivants ont été ajoutés :
- `[VALIDATION API] ===== START =====` - Début de la requête
- `[VALIDATION API] Fetching validation data for dossier: {id}` - ID du dossier
- `[VALIDATION API] Found step instances: {count}` - Nombre d'étapes trouvées
- `[VALIDATION API] Fetching documents for step_instance_id: {id}` - Pour chaque étape
- `[VALIDATION API] Found {count} documents for step_instance_id: {id}` - Nombre de documents trouvés
- `[VALIDATION API] Documents raw data: {json}` - Données brutes des documents (si présents)
- `[VALIDATION API] Step {id} summary:` - Résumé de chaque étape
- `[VALIDATION API] Transformed documents for step {id}:` - Documents transformés
- `[VALIDATION API] ===== RESPONSE SUMMARY =====` - Résumé final
- `[VALIDATION API] ===== END =====` - Fin de la requête

### 2. Logs côté client (Components)
Fichiers : 
- `partnersllc-app/components/admin/dossier/validation/StepValidationSection.tsx`
- `partnersllc-app/components/admin/dossier/validation/StepValidationCard.tsx`

Les logs suivants ont été ajoutés :
- `[STEP VALIDATION] Fetching validation data for dossier: {id}` - Début de fetch
- `[STEP VALIDATION] Received data:` - Données reçues de l'API
- `[STEP VALIDATION] Number of step instances: {count}` - Nombre d'étapes reçues
- `[STEP VALIDATION] Step {n}: {label}` - Détails de chaque étape avec documents
- `[STEP VALIDATION CARD] Rendering card for step:` - Rendu de chaque carte

## Comment utiliser les logs

1. **Ouvrir la console du navigateur** (F12 ou Cmd+Option+I sur Mac)
2. **Aller dans l'onglet Console**
3. **Filtrer les logs** en tapant `VALIDATION` dans la barre de recherche
4. **Recharger la page de validation du dossier**

## Requêtes SQL de débogage

Un fichier `debug-check-documents.sql` a été créé avec plusieurs requêtes pour vérifier :

### Requête 1 : Voir les step_instances
```sql
SELECT 
  si.id as step_instance_id,
  si.dossier_id,
  s.label as step_label,
  si.validation_status
FROM step_instances si
JOIN steps s ON s.id = si.step_id
WHERE si.dossier_id = 'YOUR_DOSSIER_ID';
```

### Requête 2 : Voir tous les documents du dossier
```sql
SELECT 
  d.id as document_id,
  d.dossier_id,
  d.step_instance_id,
  d.status,
  dt.label as document_type_label
FROM documents d
LEFT JOIN document_types dt ON dt.id = d.document_type_id
WHERE d.dossier_id = 'YOUR_DOSSIER_ID';
```

### Requête 3 : Vérifier le lien step_instance ↔ document
```sql
SELECT 
  si.id as step_instance_id,
  s.label as step_label,
  d.id as document_id,
  d.step_instance_id as doc_step_instance_id,
  CASE 
    WHEN d.step_instance_id = si.id THEN '✓ LINKED'
    WHEN d.step_instance_id IS NULL THEN '✗ NULL'
    ELSE '✗ DIFFERENT'
  END as link_status
FROM step_instances si
JOIN steps s ON s.id = si.step_id
LEFT JOIN documents d ON d.dossier_id = si.dossier_id
LEFT JOIN document_types dt ON dt.id = d.document_type_id
WHERE si.dossier_id = 'YOUR_DOSSIER_ID';
```

## Problèmes potentiels à vérifier

1. **Le document n'a pas de `step_instance_id`**
   - Vérifier que `documents.step_instance_id` n'est pas NULL
   - Si NULL, le document ne sera pas lié à une étape

2. **Le document est lié à un autre `step_instance_id`**
   - Vérifier que le `step_instance_id` du document correspond bien à celui de l'étape

3. **Problème de join dans la requête Supabase**
   - Vérifier les logs pour voir si la requête retourne des données
   - Vérifier s'il y a des erreurs Supabase

4. **Problème de transformation des données**
   - Les logs montreront les données brutes vs transformées
   - Vérifier que la structure est correcte

## Actions à faire maintenant

1. **Recharger la page de validation** et ouvrir la console
2. **Copier tous les logs** `[VALIDATION API]` et `[STEP VALIDATION]`
3. **Exécuter les requêtes SQL** dans Supabase avec l'ID de votre dossier
4. **Partager les résultats** pour identifier le problème exact
