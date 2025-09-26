**Users, Organizations & Roles (entities.sql aligned)**

- **Scope:** Defines the core concepts, data model, permissions, and API for managing users, organizations, and roles in InCustoms, aligned to `db/entities.sql`.
- **Audience:** Backend/Frontend engineers and operators integrating auth, org switching, and RBAC.

**Concepts**

- **User:** A person with login credentials. In the current schema, each user references a single `organization_id` and a single `role_id` (no many-to-many membership table).
- **Organization:** A tenant entity that owns declarations, documents, and settings.
- **Role:** RBAC level assigned directly on the user via `users.role_id`.
- (Optional, UX) **Active Organization:** If/when multi-org is needed in the future, this becomes relevant. Current schema is single-org per user.

**Roles**

- **agent:** Creates and manages drafts, uploads attachments, and can submit if allowed by org policy. No member management.
- **declarant:** Full operational authority on declarations in the org, including signing and submission. No member management.
- **moderator:** Manages organization members and their roles (up to declarant/agent). Cannot delete the organization or assign/remove admin.
- **admin:** Full control within the organization: all operational actions plus member/role management, billing/integrations, and sensitive settings. Can promote/demote moderator/agent/declarant; can transfer ownership.

Notes:
- Seed `roles.name` with: `agent`, `declarant`, `moderator`, `admin`.
- “admin” is organization-scoped. Platform super-admins (if any) are out of scope here.
- Only one role per user in this schema; choose the highest appropriate role.

**Permissions Matrix**

- **Declarations:**
  - agent: create/read/update drafts; view all org declarations; submit if policy allows; cannot cancel submitted without admin/declarant approval.
  - declarant: create/read/update/submit/sign/cancel for all org declarations.
  - moderator: read-only access to declarations; cannot submit/sign unless also declarant.
  - admin: all permissions incl. force-cancel, unlock, restore.
- **Organization Profile/Settings:**
  - agent: read.
  - declarant: read.
  - moderator: read/update non-sensitive settings.
  - admin: read/update all settings; delete/disable org; manage integrations and billing.
- **Members & Roles:**
  - agent: none.
  - declarant: none.
  - moderator: invite/remove members; assign roles agent/declarant/moderator; cannot assign/remove admin or transfer ownership.
  - admin: full; can assign/remove any role and transfer ownership.
- **Audits/Logs:**
  - agent/declarant: read their own actions.
  - moderator: read org-wide logs.
  - admin: read/export org-wide logs.

Implementation should enforce permission checks server-side. UI should hide disabled actions but never rely on UI alone.

**Data Model (from entities.sql)**

- `roles`:
  - `id` INT PK
  - `created_at` timestamptz NOT NULL
  - `updated_at` timestamptz
  - `deleted_at` timestamptz
  - `status` TEXT
  - `name` TEXT NOT NULL  // seed: agent | declarant | moderator | admin

- `organizations`:
  - `id` INT PK
  - `created_at` timestamptz NOT NULL
  - `updated_at` timestamptz
  - `deleted_at` timestamptz
  - `status` TEXT
  - `name` TEXT NOT NULL
  - `domain` TEXT NOT NULL  // org namespace
  - `verified` BOOLEAN NOT NULL

- `users`:
  - `id` INT PK
  - `created_at` timestamptz NOT NULL DEFAULT now()
  - `updated_at` timestamptz
  - `deleted_at` timestamptz
  - `status` TEXT
  - `role_id` INT FK -> `roles.id`
  - `organization_id` INT FK -> `organizations.id`
  - `first_name` TEXT NOT NULL
  - `last_name` TEXT NOT NULL
  - `middle_name` TEXT NOT NULL
  - `email` TEXT NOT NULL
  - `phone_number` TEXT NOT NULL
  - `agreement` BOOLEAN DEFAULT false

- Extended profiles (optional by user type):
  - `legal_users` (1:1 users): `inn`, `oked`, `address`, VAT fields, bank fields, customs broker registration, etc.
  - `individual_users` (1:1 users): `birthday`, `citizenship`, `address`, `pinfl`, ID document data.

Suggested indexes: seed and use `roles.name` unique; common filters on `users.organization_id`, `users.role_id`.

**API**

- `GET /roles`
  - List available roles (from `roles` table).

- `GET /users/me`
  - Returns the authenticated user with list of memberships.
  - Response example:
    {
      "id": "u_...",
      "email": "user@example.com",
      "full_name": "Alex U.",
      "organization": { "id": 1, "name": "ACME", "domain": "acme" },
      "role": { "id": 4, "name": "admin" }
    }

- `PATCH /users/me`
  - Update profile fields (`full_name`, `phone`).

- `GET /organizations`
  - List organizations (scoped as appropriate for the platform). In the current schema, users belong to one org; this may return that org.

- `POST /organizations`
  - Create an organization; typical flow also creates an initial admin user and sets `users.organization_id` and `users.role_id`.
  - Body: { "name": "ACME LLC", "domain": "acme", "verified": false }

- `GET /organizations/:orgId`
  - Read an organization; membership required.

- `PATCH /organizations/:orgId`
  - Update org settings; requires `moderator` (limited fields) or `admin` (all fields).

- `DELETE /organizations/:orgId`
  - Soft-delete/disable; requires `admin`.

- `GET /organizations/:orgId/users`
  - List users where `users.organization_id = :orgId`; requires `moderator` or `admin`.

- `POST /organizations/:orgId/users`
  - Create a user directly under the organization; requires `moderator` or `admin`.
  - Body (required): { "first_name", "last_name", "middle_name", "email", "phone_number", "role_name" }
  - Server sets `users.organization_id = :orgId` and `users.role_id` by resolving `role_name`.

- `PATCH /organizations/:orgId/users/:userId`
  - Change role or update profile; requires `moderator` (cannot set admin) or `admin` (any role).
  - Body: { "role_name": "declarant" }

- `DELETE /organizations/:orgId/users/:userId`
  - Remove (soft-delete) the user; same permissions as above. Optionally set `users.deleted_at`/`status='deleted'`.

- Note: Invitation flows are not modeled in `entities.sql`. If required, implement at the application layer or extend schema later.

Errors should use consistent problem details with `code`, `message`, and optional `details`. Return `403` for insufficient role, `404` if resource not visible in current org.

**Role Assignment Rules**

- Only `admin` can assign/remove `admin`.
- `moderator` can create/update users and set roles among { agent, declarant, moderator } (but not admin).
- A user cannot demote themselves if they are the last `admin` in the org; prevent with clear error.

**Workflows**

- Create organization and first admin:
  1) `POST /organizations` by an operator or bootstrap flow.
  2) Create initial `users` row with `organization_id` and `role_id` -> admin.

- Add organization user:
  1) `POST /organizations/:orgId/users` with personal and contact fields, and `role_name`.
  2) Resolve role, create `users` row under org.

- Change role:
  1) `PATCH /organizations/:orgId/users/:userId` with `role_name`.
  2) Validate permissions and admin/moderator limits; audit and notify.

- (Single-org) No org switching in current schema. If future multi-org is introduced, re-introduce memberships and active org state.

- Remove user from org:
  1) `DELETE /organizations/:orgId/users/:userId`.
  2) Soft-delete user row or set `status='deleted'` and revoke sessions.

**Validation & Security**

- Always scope reads/writes by `users.organization_id` from the path param/context.
- Protect against privilege escalation by validating actor’s role against target role changes.
- Record all user/role changes in an audit log with `who`, `what`, `when`, `old_value`, `new_value`.
- For sensitive actions (submit/sign), require re-auth or possession of valid digital certificate where applicable.

**Examples**

- Create user as agent:
  Request: POST `/organizations/1/users`
  Body: { "first_name": "Ali", "last_name": "Karimov", "middle_name": "A.", "email": "agent@acme.uz", "phone_number": "+99890...", "role_name": "agent" }
  Response: 201 { "id": 42, "organization_id": 1, "role": { "id": 1, "name": "agent" } }

- Promote to declarant (moderator allowed):
  Request: PATCH `/organizations/o_1/users/u_2`
  Body: { "role_name": "declarant" }

  Response: 403 { "code": "insufficient_role", "message": "Only admin can assign admin" }

**Open Questions**

- Do we introduce multi-organization membership later (separate join table) or keep single-org-per-user?
- Do we require verified digital signature binding for the `declarant` role? If yes, store certificate attributes on `users` or related table.

This document aligns with `db/entities.sql` and provides the minimum needed to implement RBAC around users, organizations, and role assignment for agent, declarant, moderator, and admin.
