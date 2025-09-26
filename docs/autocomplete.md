**Autocomplete (Per-Field, Starred, Ranked)**

- **Goal:** Provide fast, personal autocomplete for manual inputs per CCD graph/field. Persist previous inputs, allow “star/favorite”, and rank by usage + recency.
- **Why this design:** Single table is enough for the only usage (autocomplete). No heavy history or multi-field templates needed.

**Table**

- `user_field_suggestions` (see `db/autocomplete.sql`)
  - Identity: (`user_id`, `graph_no`, `field_key`, `value_fingerprint`) unique.
  - Values: `value_text` (normalized string), `value_json` (structured), optional `language`.
  - Signals: `starred`, `usage_count`, `last_used_at`, `last_entered_at`.
  - Scope: optional `organization_id` to segregate org-specific context.

**Fingerprints**

- Backend computes `value_fingerprint` to dedupe logically equal inputs:
  - Text: lower(trim(value_text)) normalized whitespace.
  - JSON: stable serialization of a canonical object (e.g., sort keys; reduce numbers to fixed decimals; include only stable keys like `codes_*_id`).

**Write Flow**

- On manual input (onBlur or after user confirms a field):
  - Upsert suggestion with `last_entered_at = now()`.
  - Do not increment `usage_count` on raw typing; only when user picks a suggestion.

- On selecting a suggestion (from dropdown):
  - `usage_count += 1`, set `last_used_at = now()`.

- On star/unstar:
  - Toggle `starred = true/false` for the suggestion.

**Read Flow (Suggest)**

- Input: `user_id`, `graph_no`, `field_key`, `q` (search text), `limit`.
- Query (prefix + ranking):
  SELECT id, value_text, value_json, starred
  FROM user_field_suggestions
  WHERE user_id = $1
    AND graph_no = $2
    AND field_key = $3
    AND ( $4 = ''
          OR lower(value_text) LIKE lower($4) || '%'
          OR value_json::text ILIKE '%' || $4 || '%')
  ORDER BY starred DESC,
           usage_count DESC,
           GREATEST(COALESCE(last_used_at, to_timestamp(0)),
                    COALESCE(last_entered_at, to_timestamp(0))) DESC
  LIMIT $5;

Notes:
- For bigger datasets, replace `LIKE` with trigram/full-text or sync to a search engine as planned.

**Retention & Pruning**

- Keep top K per (`user_id`, `graph_no`, `field_key`) by the ranking above, delete the rest periodically.
- Always keep starred suggestions regardless of K.

Example prune (per field):
  DELETE FROM user_field_suggestions
  WHERE id IN (
    SELECT id FROM (
      SELECT id,
             ROW_NUMBER() OVER (
               ORDER BY starred DESC,
                        usage_count DESC,
                        GREATEST(COALESCE(last_used_at, to_timestamp(0)),
                                 COALESCE(last_entered_at, to_timestamp(0))) DESC
             ) AS rn
      FROM user_field_suggestions
      WHERE user_id = $1 AND graph_no = $2 AND field_key = $3 AND status = 'active'
    ) t
    WHERE t.rn > $keep
  );

**Privacy & Allowlist**

- Maintain a field allowlist in code for which `graph_no/field_key` pairs are eligible for suggestions.
- Skip or hash sensitive PII (e.g., passport numbers, raw PINFL) to avoid persisting.

**Migration Note**

- If you already created `user_saved_inputs`/`user_graph_templates`, this table supersedes them for the autocomplete-only scope. Keep or drop depending on whether you plan broader “history” or “multi-field templates”.

