-- Script de diagnostic pour les notes de dossier
-- Date: 2026-01-12

-- 1. Vérifier la structure de la table dossier_notes
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'dossier_notes'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes de clé étrangère
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'dossier_notes'
  AND tc.constraint_type = 'FOREIGN KEY';

-- 3. Vérifier si RLS est activé
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'dossier_notes';

-- 4. Lister toutes les politiques RLS sur dossier_notes
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'dossier_notes'
ORDER BY policyname;

-- 5. Compter les notes par utilisateur
SELECT 
  p.full_name,
  p.role,
  COUNT(dn.id) as note_count
FROM profiles p
LEFT JOIN dossier_notes dn ON p.id = dn.user_id
WHERE p.role IN ('ADMIN', 'AGENT')
GROUP BY p.id, p.full_name, p.role
ORDER BY note_count DESC;

-- 6. Vérifier les notes récentes avec info utilisateur
SELECT 
  dn.id,
  dn.dossier_id,
  dn.user_id,
  p.full_name as user_name,
  p.role as user_role,
  LEFT(dn.note_text, 50) as note_preview,
  dn.created_at
FROM dossier_notes dn
INNER JOIN profiles p ON dn.user_id = p.id
ORDER BY dn.created_at DESC
LIMIT 10;

-- 7. Vérifier s'il existe des notes avec user_id invalides
SELECT 
  dn.id,
  dn.user_id,
  dn.dossier_id,
  dn.created_at,
  CASE 
    WHEN p.id IS NULL THEN 'ORPHAN - user not found in profiles'
    ELSE 'OK'
  END as status
FROM dossier_notes dn
LEFT JOIN profiles p ON dn.user_id = p.id
WHERE p.id IS NULL;

-- 8. Vérifier les index sur la table
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'dossier_notes'
ORDER BY indexname;
