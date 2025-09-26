**CCD Document + OCR Flow**

- **Scope:** End-to-end flow to create a CCD document, upload primary documents (invoice/contract/CMR/other), run OCR via BullMQ, receive webhook, persist OCR output, apply updates to CCD graphs, and enforce monthly OCR token limits.
- **Tables:** `ccd_documents`, `ccd_items` (db/document.sql), `files` (db/entities.sql), `ocr_jobs`, `ocr_traffic_limits` (db/ocr.sql), codes refs (db/codes.sql), FEA refs (db/fea.sql).
- **Actors:** `agent`, `declarant` can initiate CCD and upload files; `moderator`/`admin` can view and manage.

**Key Entities**

- `ccd_documents`/`ccd_items`: CCD header and per-item rows (graphs as columns/JSON); links to codes and FEA tables.
- `files`: uploaded binaries; use `uploaded_by` and `organization_id` to scope ownership.
- `ocr_jobs`: one OCR job per input file; optional links to `document_id` and `input_file_id`.
- `ocr_traffic_limits`: monthly token caps per user or per organization.

**Job Types**

- `job_type` in `ocr_jobs`: `invoice`, `contract`, `cmr`, `other`.
  - invoice: totals, currency, line items, parties → graphs 22, 23, 31, 32, 33, 41, 42, 45, 46, 47
  - contract: delivery/payment terms → graphs 20, 24; identifiers → 54/"C"
  - cmr: transport & parties → graphs 18, 19, 21, 30; possibly 2/8
  - other: free-form; map fields based on confidence and whitelist

**Sequence**

- Create CCD
  - `POST /ccd-documents` with minimal required fields: `direction_code`, `regime_code`, `form_id`, `post_id` (as needed), and ownership (`created_by_user_id`, `organization_id` from auth context).
  - Returns `document_id` for subsequent uploads.

- Upload File
  - `POST /files` (multipart) with optional `document_id` and `job_type`.
  - Persist a `files` row: `bucket`, `object_key`, `mime_type`, `size_bytes`, `uploaded_by`, `organization_id`.
  - Create an `ocr_jobs` row with: `organization_id`, `user_id`, `document_id`, `input_file_id`, `job_type`, optional `language_hint`, estimated `page_count`.
  - Enqueue BullMQ job with `ocr_jobs.id` and storage pointer (queue name e.g., `ocr:jobs`).

- Pre-Queue Limit Check (soft gate)
  - Resolve current month (`period_month` = first day of month UTC).
  - Pick scope: prefer user-level limit (`ocr_traffic_limits.user_id = current_user`); else organization-level (`organization_id = current_org`).
  - If no row exists: policy choice
    - recommended: create with default plan, or treat as unlimited for internal/testing tenants only.
  - Compute estimate: `estimated_tokens = avg_tokens_per_page * page_count` (fallback by file size).
  - Allow if:
    - `overage_allowed = true`, or
    - `used_tokens + estimated_tokens <= limit_tokens + soft_buffer`
  - `soft_buffer`: small fixed or percent (e.g., min(10_000, 0.1 * limit_tokens)) to allow slight overage because exact tokens are unknown pre-OCR.
  - If disallowed: reject upload with `403 limit_exceeded` (or place in paused state without enqueue).

- OCR Processing (worker)
  - Worker pulls job, sets `ocr_jobs.status = 'running'`.
  - Calls OCR provider; collects `tokens_prompt`, `tokens_output`, `output_data` (parsed JSON) and metadata.
  - Updates `ocr_jobs` with tokens and `status = 'succeeded'` (or `failed`).

- Webhook (Provider → API)
  - Endpoint e.g., `POST /ocr/webhook` with `{ job_id, status, tokens_prompt, tokens_output, output_data }`.
  - Idempotent: if already finalized, ignore or reconcile.
  - On success:
    - Update `ocr_jobs.tokens_*`, `output_data`, and `status`.
    - Atomically update `ocr_traffic_limits.used_tokens += tokens_total` for the corresponding `(scope, month)`; if now exceeds and `overage_allowed = false`, set `blocked_at`.
    - Apply `output_data` to CCD by graph (see Mapping) and recalculate derived fields.
  - On failure: set `ocr_jobs.status = 'failed'` and include error in `meta`; do not charge tokens unless provided.

- Apply to CCD (Mapping + Recalc)
  - General rules:
    - Only overwrite empty or user-unconfirmed fields unless confidence ≥ threshold (e.g., 0.85) or user opted-in to auto-override.
    - Keep raw `output_data` in `ocr_jobs.output_data` for traceability.
  - Typical mappings:
    - invoice → `contract_currency_id` (22), `invoice_total` (22), `contract_currency_rate` (23), per-line goods → `ccd_items` (31/32/33/41/42) with quantities/units/unit price; sum to `invoice_total`, recompute `customs_value_total` and taxes (45/46/47 logic as implemented).
    - contract → `delivery_terms_id`/`delivery_terms_place` (20), `payment_form_id` (20), `deal_type_id` (24), external ids into `external_contract_id` or 54.
    - cmr → transport and carrier fields (18, 21), container flag (19), location (30), parties hints to graphs 2/8/9/14 via FEA tables if matched.
  - Recalculate:
    - `items_count` from `ccd_items` per `document_id`.
    - `customs_value_total` from items (and currency conversions when needed).
    - Any “B” totals JSON using your tariff logic once items are present.

- File Status for User
  - Surface processing state via `ocr_jobs.status` joined by `input_file_id`.
  - Example view: latest OCR job per file with status/tokens; files remain `status='active'`, processing state is job-scoped.

**API Endpoints (suggested)**

- `POST /ccd-documents`
  - Create CCD. Body: `{ direction_code, regime_code, form_id, post_id? }`. Returns `{ id }`.

- `POST /files` (multipart)
  - Params/body: `document_id`, `job_type`, optional `language_hint`.
  - Creates `files` row and `ocr_jobs` row; enqueues BullMQ after limit check.

- `GET /ccd-documents/:id`
  - Return CCD header + items and any latest OCR job summaries for linked files.

- `POST /ocr/webhook`
  - Provider callback. Validates signature, updates `ocr_jobs`, increments traffic, applies mappings.

- `GET /files/:id/status`
  - Returns latest OCR status and tokens for the file (join to `ocr_jobs`).

- `GET /ocr/traffic` (current scope)
  - Return remaining tokens and limit for current month; indicate `blocked_at` when over limit without overage.

**SQL Snippets**

- Latest OCR status per file (for a user):
  SELECT f.id AS file_id,
         COALESCE(j.status, 'no_job') AS ocr_status,
         j.tokens_total,
         j.job_type,
         j.created_at AS ocr_created_at
  FROM files f
  LEFT JOIN LATERAL (
      SELECT *
      FROM ocr_jobs j
      WHERE j.input_file_id = f.id
      ORDER BY j.created_at DESC
      LIMIT 1
  ) j ON TRUE
  WHERE f.uploaded_by = $1
  ORDER BY f.created_at DESC;

- Upsert monthly traffic on webhook (pseudo-SQL):
  INSERT INTO ocr_traffic_limits (user_id, period_month, price_plan_id, limit_tokens, used_tokens)
  VALUES ($user_id, $period_month, $plan_id, $limit_tokens, $tokens_total)
  ON CONFLICT (user_id, period_month)
  DO UPDATE SET used_tokens = ocr_traffic_limits.used_tokens + EXCLUDED.used_tokens,
                updated_at = NOW()
  RETURNING used_tokens, limit_tokens, overage_allowed;

**BullMQ Contract**

- Queue name: `ocr:jobs`
- Job data payload:
  - `job_id` (DB `ocr_jobs.id`), `input` (S3 key / presigned URL), `job_type`, `language_hint`, `document_id?`, `organization_id`, `user_id`.
- Worker updates `ocr_jobs.status` and fills tokens on completion.
- Webhook vs. direct worker write:
  - If provider calls back to your API, use webhook; else write result directly from worker and optionally call the same apply routine.

**Limits & Enforcement**

- Before enqueue:
  - Soft check with estimate and buffer; allow if under or overage enabled.

- On completion:
  - Increment exact tokens. If exceeded and overage disabled, set `blocked_at` and prevent future enqueues for the month.

- Next upload:
  - Re-check remaining tokens. Allow small overage only within configured buffer; otherwise block until next month or plan upgrade.

**Security & Idempotency**

- Sign webhook requests and validate `job_id` belongs to `organization_id`/`user_id` in context.
- Idempotent apply: guard with `ocr_jobs.status` and a replay-safe upsert for items.
- Audit: record who/when applied OCR to CCD and what changed.

**Notes**

- Codes and FEA tables provide authoritative IDs for graphs; use them to normalize OCR outputs.
- Keep user control: present diffs and allow accept/reject per field when confidence is low.
- Token estimation heuristics can be tuned by file type and historical averages.

