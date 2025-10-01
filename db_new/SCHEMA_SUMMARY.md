# Complete Database Schema Summary

## Overview

This is a fully normalized database schema for the CCD (Customs Cargo Declaration) system with complete separation of concerns through junction tables.

---

## File Structure

```
db_new/
├── 0001_entities.sql         (17KB)  - Core platform entities
├── 0002_codes.sql            (34KB)  - All reference/dictionary tables
├── 0003_fea.sql              (13KB)  - Foreign economic activity entities
├── 0004_documents.sql        (34KB)  - Document tables (fully normalized)
├── 0005_document_joins.sql   (30KB)  - Junction tables
├── 0006_payment.sql          (29KB)  - Payment and financial tables
├── 0007_analytics_autocomplete_audit.sql (26KB) - Analytics, autocomplete, and audit tables
└── SCHEMA_SUMMARY.md         (this file)
```

**Total: 7 migration files, ~183KB of SQL**

---

## Complete Table List (86 tables total)

### 0001_entities.sql (7 tables)
1. `banks` - Bank directory
2. `organizations` - Multi-tenancy
3. `roles` - RBAC roles
4. `users` - Platform users
5. `legal_users` - Legal entity profiles (1:1 with users)
6. `individual_users` - Individual profiles (1:1 with users)
7. `files` - File storage metadata

### 0002_codes.sql (24 reference tables)
8. `codes_regimes` - Customs regimes (Graph 1) - **RENAMED from codes_forms**
9. `codes_posts` - Customs posts (Graphs 7, 29, 53)
10. `codes_countries` - Countries (Graphs 2, 11, 15, 17, 34, etc.)
11. `codes_districts` - Districts/regions (Graphs 8, 30, 31)
12. `codes_currencies` - Currencies (Graphs 13, 22, 24)
13. `codes_delivery_terms` - Incoterms (Graph 20)
14. `codes_payment_forms` - Payment forms (Graph 20)
15. `codes_deal_types` - Deal characteristics (Graph 24)
16. `codes_transport_types` - Transport types (Graphs 18, 21, 25, 26)
17. `codes_units` - Units of measurement (Graphs 33, 41)
18. `codes_hs` - HS codes (Graph 33)
19. `available_units_for_hs` - HS ↔ Units junction
20. `codes_hs_tariff_rules` - Tariff calculation rules
21. `codes_movement_types` - Movement/procedure types (Graph 37)
22. `codes_brands` - Brands (Graph 31)
23. `codes_energy_classes` - Energy efficiency classes (Graph 31)
24. `codes_manufacturers` - Manufacturers (Graph 31)
25. `codes_package_types` - Package types (Graph 31)
26. `codes_car_colors` - Car colors (Graph 31)
27. `codes_investment_programs` - Investment programs (Graph 31)
28. `codes_accompanying_documents` - Document types (Graph 44)
29. `codes_notes` - Notes/remarks (Graph 44)
30. `currency_exchange_rate` - Exchange rates (Graph 13)
31. `codes_vehicle_types` - Vehicle types (Graph 18)
32. `codes_shipment_forms` - Shipment forms (Graph 20)

### 0003_fea.sql (5 FEA tables)
33. `fea_partners` - Basic partners (country + address)
34. `fea_partners_additional` - Additional partner details
35. `fea_legal_entities_short` - Quick reference legal entities
36. `fea_legal_entities` - Full legal entity data
37. `fea_individual_entities` - Individual (physical person) data

### 0004_documents.sql (6 document tables)
38. `ccd_documents` - **Declaration header (FULLY NORMALIZED - no FK to reference tables)**
39. `ccd_items` - Declaration line items
40. `ccd_item_previous_documents` - Previous documents per item (Graph 40)
41. `ccd_item_accompanying_documents` - Accompanying documents (Graph 44)
42. `ccd_item_imei_codes` - IMEI codes (Graph 31)
43. `ccd_item_vehicle_details` - Vehicle details (Graph 31)

### 0005_document_joins.sql (18 junction tables)

#### Document ↔ Codes (13 tables)
44. `ccd_document_regimes` - Document ↔ Regimes (Graph 1)
45. `ccd_document_posts` - Document ↔ Posts (Graphs 7, 29, 53)
46. `ccd_document_countries` - Document ↔ Countries (Graphs 11, 15, 17, 18, 21, 53)
47. `ccd_document_transport_types` - Document ↔ Transport types (Graphs 18, 21, 25, 26)
48. `ccd_document_delivery_terms` - Document ↔ Delivery terms (Graph 20)
49. `ccd_document_payment_forms` - Document ↔ Payment forms (Graph 20)
50. `ccd_document_currencies` - Document ↔ Currencies (Graphs 22, 24)
51. `ccd_document_deal_types` - Document ↔ Deal types (Graph 24)
52. `ccd_document_districts` - Document ↔ Districts (Graph 30)
53. `ccd_document_movement_types` - Document ↔ Movement types (Graph 37)
54. `ccd_document_banks` - Document ↔ Banks (Graph 28)
55. `ccd_document_vehicle_types` - Document ↔ Vehicle types (Graph 18)
56. `ccd_document_shipment_forms` - Document ↔ Shipment forms (Graph 20)

#### Document ↔ FEA (4 tables)
57. `ccd_document_legal_entities` - Document ↔ Legal entities (Graphs 2, 8, 9, 14, 18, 28)
58. `ccd_document_individual_entities` - Document ↔ Individuals (Graphs 2, 8, 9, 14, 18, 28)
59. `ccd_document_legal_entities_short` - Document ↔ Legal entities short (Graphs 2, 8, 9, 14)
60. `ccd_document_partners_additional` - Document ↔ Partners additional (Graphs 2, 8, 9, 14)

#### Items ↔ Codes (4 tables)
61. `ccd_item_hs_codes` - Item ↔ HS codes (Graph 33)
62. `ccd_item_origin_countries` - Item ↔ Origin countries (Graph 34)
63. `ccd_item_units` - Item ↔ Units (Graphs 31, 41)
64. `ccd_item_districts` - Item ↔ Districts (Graph 31)

### 0006_payment.sql (12 tables)
65. `payment_providers` - Payment provider configurations (Payme, Click, Uzum, etc.)
66. `tariff_plans` - Subscription and usage-based tariff plans
67. `traffic_limits` - Traffic/usage limits for organizations
68. `ocr_jobs` - OCR processing jobs and status
69. `payment_invoices` - Payment invoices for organizations
70. `payment_invoice_items` - Line items for invoices
71. `payment_sessions` - Payment gateway sessions
72. `payment_transactions` - Payment transaction records
73. `payment_refunds` - Refund records
74. `webhook_events` - Webhook events from payment providers
75. `idempotency_keys` - Idempotency tracking for payment operations
76. `payment_audit_log` - Audit log for payment operations

### 0007_analytics_autocomplete_audit.sql (12 tables)
77. `analytics_events` - User interaction and business events
78. `analytics_sessions` - User session tracking
79. `analytics_daily_metrics` - Aggregated daily metrics
80. `autocomplete_user_history` - User-specific autocomplete history
81. `autocomplete_popular_values` - Popular autocomplete values
82. `autocomplete_suggestions_cache` - Cached autocomplete suggestions
83. `audit_log` - General audit log for all operations
84. `document_versions` - Document version history
85. `security_events` - Security-related events
86. `data_access_log` - Data access tracking
87. `dashboard_templates` - Saved dashboard templates
88. `saved_reports` - Saved report configurations

---

## ENUMs (21 total)

### From 0001_entities.sql
1. `entity_status` - active | deleted | archived
2. `storage_type` - s3 | minio | local
3. `vat_status_type` - payer | non-payer

### From 0002_codes.sql
4. `direction_code` - ИМ | ЭК | ТР
5. `tax_type` - duty | vat | excise | fee
6. `calculation_method` - ad_valorem | specific | mixed | exempt
7. `calculation_base` - customs_value | quantity | weight | custom

### From 0004_documents.sql
8. `document_status` - draft | pending | submitted | accepted | rejected | completed
9. `item_status` - draft | pending | completed
10. `eco_standard` - EURO1 | EURO2 | EURO3 | EURO4 | EURO5 | EURO6
11. `engine_type` - petrol | diesel | electric | gas | hybrid

### From 0005_document_joins.sql
12. `document_entity_role` - exporter | consignee | declarant | financial | payer | carrier
13. `document_post_type` - processing | border | transit
14. `document_country_type` - trade | dispatch | destination | vehicle_reg | border_vehicle_reg | transit_destination
15. `document_transport_role` - main | border | at_border | inside_country
16. `document_currency_type` - contract | settlement

### From 0006_payment.sql
17. `payment_provider_type` - payme | click | didox
18. `client_type` - individual | legal
19. `payment_status` - pending | processing | succeeded | failed | canceled | refunded
20. `subscription_status` - active | suspended | canceled | expired
21. `tariff_type` - free | basic | professional | enterprise
22. `usage_type` - ccd_declaration | ocr_page | api_call | storage_mb | export

### From 0007_analytics_autocomplete_audit.sql
23. `event_type` - User interaction event types
24. `audit_action` - Audit action types
25. `suggestion_type` - Autocomplete suggestion types

---

## Key Architecture Principles

### 1. Full Normalization
- `ccd_documents` has **ZERO direct foreign keys** to reference tables
- All relationships managed through junction tables
- Allows document-specific customization without changing reference data

### 2. Junction Table Pattern
Every junction table includes:
- `id` (PK)
- `document_id` or `item_id` (FK with CASCADE DELETE)
- `{reference_table}_id` (FK to reference table)
- `role/type` discriminator field (where applicable)
- `custom_*` fields for document-specific overrides
- Standard audit fields (created_at, updated_at, deleted_at, status)

### 3. Type Safety
- PostgreSQL ENUMs used extensively
- Database-level validation
- Clear, type-safe queries

### 4. Historical Integrity
- Documents retain their data even if reference tables change
- Soft delete support throughout (deleted_at field)
- Audit trail on all tables

### 5. Flexibility
- Multiple entries of same reference per document (with different roles)
- Custom values override reference data when needed
- JSON fields for unstructured/flexible data

---

## Graph Coverage

All graphs from `docs/graphs.md` are fully covered:

| Graph | Description | Location |
|-------|-------------|----------|
| 1 | Customs regime | `ccd_document_regimes` |
| 2 | Exporter | `ccd_document_*_entities` (role='exporter') |
| 7 | Processing post | `ccd_document_posts` (type='processing') |
| 8 | Consignee | `ccd_document_*_entities` (role='consignee') |
| 9 | Financial | `ccd_document_*_entities` (role='financial') |
| 11 | Trade country | `ccd_document_countries` (type='trade') |
| 13 | USD/UZS rate | `ccd_documents.usd_uzs_rate` |
| 14 | Declarant | `ccd_document_*_entities` (role='declarant') |
| 15 | Dispatch country | `ccd_document_countries` (type='dispatch') |
| 17 | Destination country | `ccd_document_countries` (type='destination') |
| 18 | Main transport | `ccd_document_transport_types` (role='main') |
| 20 | Delivery terms | `ccd_document_delivery_terms` |
| 20 | Payment forms | `ccd_document_payment_forms` |
| 22 | Contract currency | `ccd_document_currencies` (type='contract') |
| 24 | Deal type | `ccd_document_deal_types` |
| 24 | Settlement currency | `ccd_document_currencies` (type='settlement') |
| 28 | Payer bank | `ccd_document_banks` |
| 29 | Border post | `ccd_document_posts` (type='border') |
| 30 | Location district | `ccd_document_districts` |
| 31 | Item details | `ccd_items` + extended tables |
| 33 | HS code | `ccd_item_hs_codes` |
| 34 | Origin country | `ccd_item_origin_countries` |
| 37 | Movement type | `ccd_document_movement_types` |
| 40 | Previous docs | `ccd_item_previous_documents` |
| 44 | Accompanying docs | `ccd_item_accompanying_documents` |
| 53 | Transit post | `ccd_document_posts` (type='transit') |

---

## Migration Order

Execute in this exact order:

```bash
psql < 0001_entities.sql
psql < 0002_codes.sql
psql < 0003_fea.sql
psql < 0004_documents.sql
psql < 0005_document_joins.sql
psql < 0006_payment.sql
psql < 0007_analytics_autocomplete_audit.sql
```

---

## Benefits of This Architecture

✅ **Clean separation** - Documents don't directly depend on reference data
✅ **Historical accuracy** - Documents keep their values even if references change
✅ **Flexibility** - Multiple roles per reference, custom overrides
✅ **Performance** - Smaller main tables, targeted indexes
✅ **Maintainability** - Clear structure, well-documented
✅ **Type safety** - ENUMs provide database-level validation
✅ **Auditability** - Full audit trail on all tables
✅ **Scalability** - Join only what you need

---

## Example Query Pattern

### Old Schema (Direct FK):
```sql
SELECT d.*, c.name as country_name
FROM ccd_documents d
LEFT JOIN codes_countries c ON d.trade_country_id = c.id;
```

### New Schema (Junction Table):
```sql
SELECT d.*,
       COALESCE(dc.custom_name, c.name) as country_name
FROM ccd_documents d
LEFT JOIN ccd_document_countries dc ON d.id = dc.document_id
                                    AND dc.country_type = 'trade'
LEFT JOIN codes_countries c ON dc.codes_countries_id = c.id;
```

The new pattern allows:
- Document-specific country name overrides
- Multiple countries of different types per document
- Historical data preservation

---

## Statistics

- **Total Tables**: 88
- **Total ENUMs**: 25
- **Junction Tables**: 22
- **Reference Tables**: 24
- **Document Tables**: 6
- **FEA Tables**: 5
- **Payment Tables**: 12
- **Analytics/Audit Tables**: 12
- **Core Entity Tables**: 7
- **Lines of SQL**: ~5,500
- **Total Size**: ~183KB
