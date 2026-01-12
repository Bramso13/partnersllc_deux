# Correction : Validation des Documents

## Problème identifié

La requête Supabase utilisait un mauvais pattern pour récupérer les documents et leurs versions :
- Utilisation d'un `inner join` sur `document_types` qui excluait les documents sans type
- Tentative de récupération de la version via un foreign key join qui ne fonctionnait pas correctement
- Pas de logs détaillés pour déboguer

## Corrections apportées

### 1. API de validation (`/api/admin/dossiers/[id]/validation/route.ts`)

#### Changements dans la requête documents :
```typescript
// AVANT (ne fonctionnait pas)
const { data: documents } = await supabase
  .from("documents")
  .select(`
    id, dossier_id, ...,
    document_types!inner (...),  // ❌ inner join exclut docs sans type
    current_version:document_versions!documents_current_version_id_fkey (...)  // ❌ Ne fonctionne pas
  `)
  .eq("step_instance_id", si.id);

// APRÈS (corrigé)
const { data: documents } = await supabase
  .from("documents")
  .select(`
    id, dossier_id, ...,
    current_version_id,
    document_types (...)  // ✅ Left join par défaut
  `)
  .eq("step_instance_id", si.id);

// Puis récupération séparée des versions
const documentsWithVersions = await Promise.all(
  (documents || []).map(async (doc) => {
    if (!doc.current_version_id) return { ...doc, current_version: null };
    
    const { data: version } = await supabase
      .from("document_versions")
      .select("id, file_url, file_name, file_size_bytes, mime_type, uploaded_at")
      .eq("id", doc.current_version_id)
      .single();
    
    return { ...doc, current_version: version };
  })
);
```

### 2. Routes d'approbation/rejet

#### Ajout de validations :
- Vérification que le document a un `current_version_id`
- Logs détaillés à chaque étape
- Vérification de la création de la review

#### Flux d'approbation :
```
1. Vérifier que le document existe et appartient au dossier
2. Vérifier qu'il a une version courante (current_version_id)
3. Mettre à jour le statut du document (APPROVED/REJECTED)
4. Créer un enregistrement dans document_reviews avec :
   - document_version_id (lié à current_version_id)
   - reviewer_id (agent qui fait la validation)
   - status (APPROVED/REJECTED)
   - reason (pour les rejets)
   - reviewed_at (timestamp)
```

### 3. Logs ajoutés

#### API côté serveur :
```
[VALIDATION API] ===== START =====
[VALIDATION API] Fetching documents for step_instance_id: {id}
[VALIDATION API] Found {n} documents for step_instance_id: {id}
[VALIDATION API] Document {id} has no current_version_id (si aucune version)
[VALIDATION API] Found version for document {id}: {version_data}
[VALIDATION API] Transforming document {id}: {details}
[VALIDATION API] Step {id} summary: {compteurs}
[VALIDATION API] ===== END =====

[APPROVE DOC] / [REJECT DOC] Document not found: {id}
[APPROVE DOC] / [REJECT DOC] Approving/Rejecting document: {details}
[APPROVE DOC] / [REJECT DOC] Document review created: {review_id}
[APPROVE DOC] / [REJECT DOC] Document approved/rejected successfully: {id}
```

## Structure de données

### Table `documents`
```sql
- id (uuid)
- dossier_id (uuid) → référence au dossier
- step_instance_id (uuid) → référence à l'étape (CLEF pour lier le document à une étape)
- document_type_id (uuid) → type de document
- status (enum) → PENDING, APPROVED, REJECTED, OUTDATED
- current_version_id (uuid) → pointe vers la version active dans document_versions
```

### Table `document_versions`
```sql
- id (uuid)
- document_id (uuid) → référence au document parent
- file_url (text) → URL du fichier
- file_name (text) → Nom du fichier
- file_size_bytes (bigint) → Taille
- mime_type (text) → Type MIME
- version_number (int) → Numéro de version
- uploaded_at (timestamp)
```

### Table `document_reviews`
```sql
- id (uuid)
- document_version_id (uuid) → référence à la version reviewée
- reviewer_id (uuid) → agent qui a fait la review
- status (enum) → APPROVED, REJECTED
- reason (text) → raison du rejet (optionnel)
- notes (text) → notes additionnelles
- reviewed_at (timestamp)
```

## Comment tester

1. **Console navigateur** : Ouvrir la console et filtrer par `[VALIDATION API]` ou `[APPROVE DOC]`
2. **Vérifier la présence des documents** :
   - Les logs montreront combien de documents sont trouvés pour chaque step_instance
   - Les logs montreront si le document a une version ou non
3. **Tester l'approbation/rejet** :
   - Cliquer sur "Approuver" ou "Rejeter"
   - Vérifier dans les logs que la review est créée
   - Vérifier dans Supabase que l'enregistrement existe dans `document_reviews`

## Requête SQL pour vérifier

```sql
-- Voir les documents avec leurs versions et reviews
SELECT 
  d.id as document_id,
  d.step_instance_id,
  d.status as doc_status,
  dt.label as type,
  dv.file_name,
  dv.uploaded_at,
  dr.status as review_status,
  dr.reason as review_reason,
  dr.reviewed_at,
  a.name as reviewer_name
FROM documents d
LEFT JOIN document_types dt ON dt.id = d.document_type_id
LEFT JOIN document_versions dv ON dv.id = d.current_version_id
LEFT JOIN document_reviews dr ON dr.document_version_id = d.current_version_id
LEFT JOIN agents a ON a.id = dr.reviewer_id
WHERE d.dossier_id = 'YOUR_DOSSIER_ID'
ORDER BY d.created_at DESC;
```

## Points importants

✅ **Le document DOIT avoir un `step_instance_id`** pour apparaître dans la validation d'une étape  
✅ **Le document DOIT avoir un `current_version_id`** pour pouvoir être visualisé et validé  
✅ **La review est liée à `document_version_id`** (pas au document directement)  
✅ **Le statut est sur le document** (`documents.status`), pas sur la review  
✅ **Les logs montrent maintenant chaque étape** du processus pour faciliter le débogage
