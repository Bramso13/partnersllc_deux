-- Script de diagnostic pour vérifier les politiques RLS sur la table events
-- Date: 2026-01-12

-- 1. Vérifier si RLS est activé sur la table events
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'events';

-- 2. Lister toutes les politiques RLS sur la table events
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
WHERE tablename = 'events'
ORDER BY policyname;

-- 3. Vérifier les fonctions de trigger et leur sécurité
SELECT 
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_definition,
  CASE 
    WHEN p.prosecdef THEN 'SECURITY DEFINER'
    ELSE 'SECURITY INVOKER'
  END as security_type
FROM pg_proc p
WHERE p.proname IN ('create_dossier_status_event', 'create_document_upload_event');

-- 4. Vérifier les triggers sur document_versions
SELECT 
  t.tgname as trigger_name,
  p.proname as function_name,
  pg_get_triggerdef(t.oid) as trigger_definition
FROM pg_trigger t
INNER JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'document_versions'::regclass
  AND NOT t.tgisinternal;

-- 5. Compter les événements par type
SELECT 
  event_type,
  entity_type,
  COUNT(*) as count,
  MAX(created_at) as last_created
FROM events
GROUP BY event_type, entity_type
ORDER BY event_type, entity_type;

-- 6. Vérifier les événements récents de type DOCUMENT_UPLOADED
SELECT 
  id,
  entity_type,
  entity_id,
  event_type,
  payload,
  created_at
FROM events
WHERE event_type = 'DOCUMENT_UPLOADED'
ORDER BY created_at DESC
LIMIT 5;
