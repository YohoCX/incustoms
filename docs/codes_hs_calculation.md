**HS Codes: Calculation Rules**

- **Scope:** How to model and use HS-based tariff data to compute Graphs 45/46/47 using `codes_hs`, `available_units_for_hs`, and `codes_hs_tariff_rules`.
- **Tables:** `codes_hs` (with measurement flags), `available_units_for_hs`, `codes_units`, `codes_countries`, `codes_hs_tariff_rules`.

**Key Fields**

- `codes_hs.requires_net_mass`: Enforce that `ccd_items.net_weight_kg` is provided for this HS.
- `codes_hs.requires_additional_unit`: Enforce `ccd_items.additional_unit_id` and `additional_unit_qty`.
- `codes_hs.specific_rate_default_unit_id`: Default unit for specific rates when a rule omits `specific_unit_id`.
- `available_units_for_hs`: Whitelist allowed measurement units for Graph 33 and the right-lower block of Graph 31.

**Tariff Rules (`codes_hs_tariff_rules`)**

- Filters: `codes_hs_id`, optional `direction_code` ('ИМ'|'ЭК'|'ТР'), optional `regime_code`, optional `origin_country_id`, optional `preference_code`.
- Kind: `tax_type` in {'duty','vat','excise','fee'}; `method` in {'ad_valorem','specific','mixed','exempt'}.
- Parameters:
  - `ad_valorem_rate`: percent value (e.g., 10.0 means 10%).
  - `specific_amount`: per-unit amount in the rule’s `specific_unit_id` (or HS default unit).
  - `base`: 'customs_value' | 'quantity' | 'weight' | 'custom'.
  - `valid_from`/`valid_to`: date window; use current date in production.
  - `priority`: lower wins when multiple rules match.

Notes:
- Mixed method default: compute both ad valorem and specific and take the maximum; if different behavior is required, encode via separate rules and business logic keyed by `notes/legal_basis`.

**Selection Logic (pseudocode)**

1) Gather all rules for `hs_id` and `tax_type` where:
   - `rule.direction_code` is NULL or equals item direction.
   - `rule.regime_code` is NULL or equals document regime.
   - `rule.origin_country_id` is NULL or equals item origin.
   - `rule.preference_code` matches any active preference (optional).
   - `valid_from`/`valid_to` cover current date.
2) Sort by `priority ASC`, then most-specific (non-NULL) conditions.
3) Pick the first rule per `tax_type`.

**Computation**

- Base values per item:
  - customs_value := `ccd_items.customs_value` (or computed from `invoiced_value` + adjustments per regime).
  - quantity := `additional_unit_qty` in `additional_unit_id`.
  - weight := `net_weight_kg`.

- Formulas:
  - ad_valorem: `amount = customs_value * (ad_valorem_rate / 100)`
  - specific: `amount = normalized_quantity * specific_amount`
    - Normalize quantity into `specific_unit_id` (or HS default) as needed.
  - mixed: `max(ad_valorem_amount, specific_amount)` (default policy)
  - exempt: `amount = 0`

- VAT base: customs value + duties + excise (country-specific). Compute VAT rule after duty/excise.

**Example Queries**

- Select applicable rule (simplified; choose by lowest priority and validity):
  WITH rules AS (
    SELECT r.*
    FROM codes_hs_tariff_rules r
    WHERE r.codes_hs_id = $1
      AND r.tax_type = $2 -- 'duty'|'vat'|'excise'|'fee'
      AND (r.direction_code IS NULL OR r.direction_code = $3)
      AND (r.regime_code IS NULL OR r.regime_code = $4)
      AND (r.origin_country_id IS NULL OR r.origin_country_id = $5)
      AND (r.valid_from IS NULL OR r.valid_from <= $6::date)
      AND (r.valid_to   IS NULL OR r.valid_to   >= $6::date)
    ORDER BY r.priority ASC
  )
  SELECT * FROM rules LIMIT 1;

- Validate HS measurement requirements:
  SELECT h.requires_net_mass, h.requires_additional_unit
  FROM codes_hs h
  WHERE h.id = $hs_id;

**Integration Points**

- CCD item save: enforce required measurements per HS; block or warn when missing.
- Payment builder (Graph 47): resolve rules by HS and compute per-item duty, excise, VAT.
- OCR mapping: when `output_data` includes quantities/weights, ensure alignment with HS unit requirements before calculations.

**Open Extensions**

- Preference catalogs (e.g., GSP) can be normalized into a separate table and linked via `preference_code`.
- Add `mixed_mode` (max/sum/custom) if required by legal basis.
- Add seasonal/quota rules with extra condition columns if applicable.

