-- Check what's in step_document_types
SELECT
  sdt.id,
  sdt.product_step_id,
  sdt.document_type_id,
  dt.code as doc_type_code,
  dt.label as doc_type_label,
  ps.product_id
FROM step_document_types sdt
LEFT JOIN document_types dt ON dt.id = sdt.document_type_id
LEFT JOIN product_steps ps ON ps.id = sdt.product_step_id
WHERE ps.product_id = '550e8400-e29b-41d4-a716-446655440001'
ORDER BY sdt.product_step_id;
