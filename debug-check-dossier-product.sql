-- Check which product is used by the dossier
SELECT
  d.id as dossier_id,
  d.product_id,
  p.code as product_code,
  p.name as product_name
FROM dossiers d
LEFT JOIN products p ON p.id = d.product_id
WHERE d.id = '8db28436-5a40-4dd4-a1c8-660ffbcf8f8f';
