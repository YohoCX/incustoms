**CCD Audit Log**

- **Purpose:** Trace who changed what and how in a CCD (document and items). Useful for reviews, dispute resolution, and showing a human-readable change log per graph/field.

**Tables**

- `ccd_audit_events` (db/audit.sql)
  - Scope: `document_id` (required), optional `item_id`, `organization_id`, `user_id`.
  - Field context: `graph_no`, `field_key` (optional for coarse actions).
  - Action: `create | update | delete | apply_template | apply_ocr | status_change | system`.
  - Source: `manual | ocr | template | api | system`.
  - Values: `old_value` (json), `new_value` (json).
  - Extra: `reason` (text), `meta` (json) for anything else (e.g., `ocr_job_id`, IP, client version).

- `ccd_status_history` (db/audit.sql)
  - Focused list of status transitions with timestamps and optional `user_id`/`reason`.

**When to Write Events**

- On document creation: one `create` event with minimal header payload.
- On manual field change: an `update` event per field (graph_no + field_key) including `old_value`/`new_value`.
- On template apply: one `apply_template` event per field changed (or a single coarse entry with list in `meta.changed_fields`).
- On OCR apply: one `apply_ocr` event per field changed; include `ocr_job_id` and confidence in `meta`.
- On item add/remove: `create`/`delete` events with `item_id` and snapshot payload.
- On status change: both a `status_change` event and a row in `ccd_status_history`.

**Read Patterns**

- Document timeline:
  SELECT * FROM ccd_audit_events
  WHERE document_id = $1
  ORDER BY created_at DESC;

- Field history (graph 22, currency):
  SELECT created_at, user_id, source, old_value, new_value
  FROM ccd_audit_events
  WHERE document_id = $1 AND graph_no = 22 AND field_key = 'contract_currency_id'
  ORDER BY created_at DESC;

- Latest status changes:
  SELECT * FROM ccd_status_history
  WHERE document_id = $1
  ORDER BY created_at DESC;

**API Sketch**

- `POST /ccd-documents/:id/audit`
  - Body: { item_id?, graph_no?, field_key?, action, source, old_value?, new_value?, reason?, meta? }
  - Auth binds `user_id` and `organization_id` when present.

- `GET /ccd-documents/:id/audit`
  - Query: graph_no?, field_key?, item_id?, limit, after (cursor)
  - Returns events ordered by `created_at DESC`.

**Best Practices**

- Store values as compact JSON; for foreign keys, keep `{ id, code, display }` to retain meaning over time.
- Avoid PII in `reason`/`meta` unless necessary; respect privacy policies.
- Keep event size modest (split very large diffs into multiple rows or store a pointer in `meta`).

**Optional Triggers**

- You can add DB triggers to automatically record status changes in `ccd_status_history` whenever `ccd_documents.status` updates. Field-level audit is better done at the service layer where you know the `graph_no` and `field_key`.

