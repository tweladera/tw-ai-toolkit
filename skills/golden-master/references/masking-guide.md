# Golden Master — Normalization & Masking Guide

This guide defines which values are normalized before saving or comparing Golden Master outputs.
Normalization makes comparisons deterministic and protects sensitive data.

## Default Normalization Rules (tolerance=normalized)

Applied in this order before any comparison or save operation.

| Pattern | Replacement | Rationale |
|---|---|---|
| UUID v4: `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}` | `<UUID>` | Auto-generated IDs change every run |
| ISO 8601 timestamp: `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z?` | `<TIMESTAMP>` | Dates change every run |
| Unix epoch (13-digit ms): `\b1[67]\d{12}\b` | `<EPOCH_MS>` | Same as above |
| Auto-increment integer ID in JSON: `"id"\s*:\s*\d+` | `"id": <ID>` | DB auto-increment is non-deterministic across environments |
| Secret field names: `"(password|token|secret|key|authorization|api_key|access_token|refresh_token)"\s*:\s*"[^"]*"` | `"$1": "<REDACTED>"` | Never capture secrets in Golden Masters |
| Bearer token in headers: `Bearer [A-Za-z0-9\-_\.]+` | `Bearer <TOKEN>` | Same as above |

## What is NOT Normalized

These values are intentionally preserved for comparison:

- Business data: amounts, quantities, prices, names, addresses, status codes
- Error messages and codes — changes here are meaningful regressions
- Boolean values
- Array lengths and ordering
- HTTP status codes
- Field names (schema changes are regressions)
- Enum values

## Custom Normalization Rules

To add project-specific normalization rules, create a `.golden/masking.json` in your project:

```json
{
  "custom_masks": [
    {
      "pattern": "\"correlation_id\":\\s*\"[^\"]*\"",
      "replacement": "\"correlation_id\": \"<CORRELATION_ID>\"",
      "reason": "Generated per-request, not deterministic"
    },
    {
      "pattern": "\"session_id\":\\s*\"[^\"]*\"",
      "replacement": "\"session_id\": \"<SESSION_ID>\"",
      "reason": "Session IDs change per test run"
    }
  ],
  "pii_fields": [
    "email",
    "phone",
    "cpf",
    "rut",
    "passport_number"
  ]
}
```

PII fields listed under `pii_fields` will be replaced with `<PII>` regardless of value.

## strict mode (tolerance=strict)

When `tolerance=strict` is used, NO normalization is applied. Every byte must match exactly.

Only use strict mode for:
- Deterministic functions with no IDs, dates, or random values
- Report generation with fixed inputs and expected fixed outputs
- Hash/checksum validation

## Security Checklist Before Committing a Golden Master

Before adding `.golden/` files to version control, verify:

- [ ] No passwords, tokens, or API keys in captured outputs
- [ ] No PII (email, phone, national ID, passport) unless project policy allows it
- [ ] No internal infrastructure details (internal IPs, internal service names) that could aid attackers
- [ ] No data from production systems — Golden Masters should use synthetic/test data only

If in doubt, add `.golden/` to `.gitignore` and share masters via a shared test artifact store.
