-- Script de débogage pour vérifier les documents liés aux step_instances
-- Remplacez 'YOUR_DOSSIER_ID' par l'ID réel de votre dossier

-- 1. Voir tous les step_instances pour un dossier
SELECT 
  si.id as step_instance_id,
  si.dossier_id,
  s.label as step_label,
  si.validation_status,
  si.started_at,
  si.completed_at
FROM step_instances si
JOIN steps s ON s.id = si.step_id
WHERE si.dossier_id = 'YOUR_DOSSIER_ID'
ORDER BY si.started_at;

-- 2. Voir tous les documents dans la BDD
SELECT 
  d.id as document_id,
  d.dossier_id,
  d.step_instance_id,
  d.status,
  dt.label as document_type_label,
  dt.code as document_type_code,
  d.current_version_id,
  d.created_at
FROM documents d
LEFT JOIN document_types dt ON dt.id = d.document_type_id
ORDER BY d.created_at DESC
LIMIT 20;

-- 3. Voir les documents pour un dossier spécifique
SELECT 
  d.id as document_id,
  d.dossier_id,
  d.step_instance_id,
  d.status,
  dt.label as document_type_label,
  dt.code as document_type_code,
  d.current_version_id,
  d.created_at,
  dv.file_name,
  dv.file_url
FROM documents d
LEFT JOIN document_types dt ON dt.id = d.document_type_id
LEFT JOIN document_versions dv ON dv.id = d.current_version_id
WHERE d.dossier_id = 'YOUR_DOSSIER_ID'
ORDER BY d.created_at;

-- 4. Vérifier la relation entre documents et step_instances
SELECT 
  si.id as step_instance_id,
  s.label as step_label,
  d.id as document_id,
  d.step_instance_id as doc_step_instance_id,
  dt.label as document_type_label,
  d.status,
  CASE 
    WHEN d.step_instance_id = si.id THEN '✓ LINKED'
    WHEN d.step_instance_id IS NULL THEN '✗ NULL'
    ELSE '✗ DIFFERENT'
  END as link_status
FROM step_instances si
JOIN steps s ON s.id = si.step_id
LEFT JOIN documents d ON d.dossier_id = si.dossier_id
LEFT JOIN document_types dt ON dt.id = d.document_type_id
WHERE si.dossier_id = 'YOUR_DOSSIER_ID'
ORDER BY si.started_at, d.created_at;

-- 5. Compter les documents par step_instance
SELECT 
  si.id as step_instance_id,
  s.label as step_label,
  COUNT(d.id) as document_count,
  COUNT(CASE WHEN d.status = 'APPROVED' THEN 1 END) as approved_count,
  COUNT(CASE WHEN d.status = 'PENDING' THEN 1 END) as pending_count,
  COUNT(CASE WHEN d.status = 'REJECTED' THEN 1 END) as rejected_count
FROM step_instances si
JOIN steps s ON s.id = si.step_id
LEFT JOIN documents d ON d.step_instance_id = si.id
WHERE si.dossier_id = 'YOUR_DOSSIER_ID'
GROUP BY si.id, s.label
ORDER BY si.started_at;
