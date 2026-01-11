-- Check ALL data in step_document_types
SELECT
  sdt.id,
  sdt.product_step_id,
  sdt.document_type_id,
  dt.code as doc_type_code,
  dt.label as doc_type_label,
  ps.product_id
FROM step_document_types sdt
LEFT JOIN document_types dt ON dt.id = sdt.document_type_id
LEFT JOIN product_steps ps ON ps.id = sdt.product_step_id;
