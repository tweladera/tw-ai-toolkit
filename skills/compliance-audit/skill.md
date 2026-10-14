---
name: compliance-audit
description: Generates a compliance gap report and test checklist for GDPR, HIPAA, PCI-DSS, SOX, or ISO 27001. Scans the codebase for compliance-relevant patterns (PII handling, audit logging, data retention, encryption) and maps findings to specific regulatory articles.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: framework
    type: string
    required: true
    default: ""
    description: "Compliance framework(s): 'gdpr', 'hipaa', 'pci-dss', 'sox', 'iso27001', or comma-separated for multiple (e.g. 'gdpr,hipaa'). Use 'all' to apply all frameworks."
  - name: industry
    type: string
    required: false
    default: ""
    description: "Industry context for risk prioritization: 'healthcare', 'finance', 'retail', 'government', 'saas'. Adjusts which requirements are critical vs. informational."
  - name: mode
    type: string
    required: false
    default: "assess"
    description: "'assess' to analyze current state and generate gap report, 'checklist' to generate a test checklist only (no code scanning), 'full' for both."
  - name: output
    type: string
    required: false
    default: "report"
    description: "'report' for full compliance gap analysis, 'checklist' for an actionable test checklist, 'csv' for import into GRC tools."
tags:
  - compliance
  - gdpr
  - hipaa
  - pci-dss
  - sox
  - iso27001
  - regulatory
  - security
  - qa
invocation: tw-compliance-audit
---

# compliance-audit

## Description

Regulatory compliance is not optional in enterprise engagements. A consultant joining a
healthcare startup needs HIPAA; a European fintech needs GDPR + PCI-DSS; a publicly traded
US company needs SOX. Without a compliance baseline, the QA conversation is incomplete —
and in some industries, the legal exposure is significant.

`compliance-audit` does two things:
1. **Scans the codebase** for patterns that indicate compliance gaps (or compliance coverage)
2. **Generates a test checklist** specific to the selected regulatory framework — tests that
   must exist for the application to demonstrate compliance

**Supported frameworks:**

| Framework | Audience | Key focus |
|---|---|---|
| GDPR | Any company processing EU personal data | Consent, right to erasure, data minimization, breach notification |
| HIPAA | US healthcare apps and their business associates | PHI protection, audit controls, access management, breach notification |
| PCI-DSS | Any app that processes payment card data | Card data encryption, network segmentation, access control, logging |
| SOX | Publicly traded US companies and their software | Financial data integrity, audit trails, change management |
| ISO 27001 | Enterprise information security management | Risk management, asset control, incident response, business continuity |

## When to Use

- First week on a new client engagement — establish the compliance baseline
- When a client mentions regulatory requirements — understand the gap immediately
- Before a security audit or penetration test — compliance gaps are often found there first
- When onboarding a new team member to compliance requirements

Triggers: "GDPR compliance", "are we HIPAA compliant", "PCI audit prep", "compliance checklist",
"regulatory requirements", "data privacy".

## Instructions

### Step 1 — Identify PII and Sensitive Data Flows

```bash
# Detect PII field names in models/entities
rg "email|phone|ssn|social.?security|date.?of.?birth|dob|credit.?card|pan|passport" \
  src/ -i --type ts --type py --type java | grep -v "test\|spec" | head -30

# Detect data serialization (what gets sent over the wire)
rg "class.*Dto|class.*Response|@ApiProperty|Serializer|schema.*fields" \
  src/ --type ts --type py | head -20

# Detect data storage
rg "@Column\|@Entity\|models\.Model\|@Table" src/ --type ts --type py --type java | head -20

# Detect third-party data sharing
rg "http\.post\|axios\.post\|requests\.post\|restTemplate\.post" \
  src/ --type ts --type py --type java | head -20
```

### Step 2a — GDPR Assessment

Key GDPR articles mapped to code patterns:

**Art. 17 — Right to Erasure (Right to be Forgotten)**
```bash
# Check for delete/anonymize user data endpoints
rg "deleteUser\|anonymize\|purgeData\|gdprDelete\|rightToErasure" \
  src/ -i | head -10

# Check for cascade delete on user data
rg "onDelete.*CASCADE\|cascade.*delete" src/ -i | head -10
```

**Art. 7 — Consent Management**
```bash
# Consent recording
rg "consent\|gdprConsent\|cookieConsent\|acceptedTerms" \
  src/ -i | head -10
```

**Art. 33 — Breach Notification (72-hour requirement)**
```bash
# Incident/breach detection and alerting
rg "SecurityEvent\|DataBreach\|IncidentReport\|alerting" \
  src/ -i | head -10
```

**Art. 25 — Data Minimization (Privacy by Design)**
```bash
# Check DTOs — are they returning more than needed?
rg "password|ssn|secret" src/ --include="*dto*" --include="*response*" | head -10
```

**Art. 30 — Records of Processing Activities**
```bash
# Audit logging for data processing operations
rg "AuditLog\|processLog\|dataProcessing" src/ -i | head -10
```

**GDPR Test Checklist generated:**
```markdown
## GDPR Test Checklist

### Art. 17 — Right to Erasure
- [ ] DELETE /api/users/:id removes all personal data (name, email, phone, address)
- [ ] Cascade deletion covers related records (orders, sessions, preferences)
- [ ] Anonymization preserves statistical data without PII
- [ ] Deletion is logged with timestamp and requesting party
- [ ] Third-party systems are notified of deletion (via event/webhook)

### Art. 7 — Consent
- [ ] Consent is recorded with timestamp and version of terms
- [ ] Consent can be withdrawn and withdrawal is processed
- [ ] Marketing consent is separate from service consent
- [ ] Underage users (< 16) require parental consent

### Art. 33 — Breach Notification
- [ ] Security events trigger an alert within 1 hour of detection
- [ ] Breach notification workflow reaches the DPO
- [ ] Test: simulate unauthorized data access → verify alert fires

### Art. 25 — Data Minimization
- [ ] API responses do not include fields not needed by the caller
- [ ] Logs do not contain passwords, credit card numbers, or SSNs
- [ ] Test: assert that GET /api/users/:id does not return password hash

### Art. 32 — Security of Processing
- [ ] Personal data is encrypted at rest (AES-256 or equivalent)
- [ ] Personal data is encrypted in transit (TLS 1.2+)
- [ ] Database access requires authentication (no anonymous access)
```

### Step 2b — HIPAA Assessment

**Key HIPAA Safeguards:**

```bash
# PHI (Protected Health Information) field detection
rg "diagnosis|condition|medication|prescription|mrn|medical.?record|patient|treatment" \
  src/ -i | grep -v "test\|spec" | head -20

# Access controls
rg "@Roles\|@HasPermission\|hasRole\|checkPermission" \
  src/ --type ts --type java | head -10

# Audit controls — HIPAA requires audit logs for all PHI access
rg "AuditLog\|hipaaAudit\|phiAccess\|accessLog" src/ -i | head -10

# Automatic logoff (required by HIPAA §164.312)
rg "sessionTimeout\|inactivityTimeout\|autoLogout" src/ -i | head -10
```

**HIPAA Test Checklist generated:**
```markdown
## HIPAA Test Checklist

### Technical Safeguards (§164.312)

#### Access Control
- [ ] Each user has a unique ID — no shared accounts
- [ ] Minimum necessary access — role-based authorization verified per endpoint
- [ ] Encryption key management for ePHI at rest
- [ ] Emergency access procedure exists and is tested

#### Audit Controls
- [ ] All PHI reads are logged (who, what, when)
- [ ] All PHI writes/updates are logged
- [ ] All PHI deletions are logged
- [ ] Log tampering is detected and alerted

#### Transmission Security
- [ ] All PHI transmitted over TLS 1.2+
- [ ] No PHI in URL query parameters
- [ ] No PHI in log files

#### Automatic Logoff
- [ ] Sessions expire after [15 minutes] of inactivity
- [ ] Test: verify session token is invalidated after timeout

### Breach Notification (§164.400)
- [ ] Unauthorized PHI access triggers notification within 60 days
- [ ] Notification reaches covered entity within defined SLA
```

### Step 2c — PCI-DSS Assessment

```bash
# Card data (PAN) detection
rg "\b4[0-9]{12}(?:[0-9]{3})?\b|\b5[1-5][0-9]{14}\b" src/ | head -5  # potential PANs in code
rg "cardNumber|pan|cvv|cvv2|cvc|creditCard" src/ -i | grep -v "test\|spec" | head -10

# Tokenization check
rg "token\|tokenize\|paymentToken" src/ -i | head -10

# TLS enforcement
rg "http://" src/ config/ | grep -v "localhost\|127\.0\.0\.1\|test" | head -10
```

**PCI-DSS Test Checklist (key requirements):**
```markdown
## PCI-DSS Test Checklist

### Req 3 — Protect Stored Cardholder Data
- [ ] PANs are masked in display (show only last 4 digits)
- [ ] PANs are never stored after authorization (use tokenization)
- [ ] CVV/CVV2 is NEVER stored (not even encrypted)
- [ ] Test: verify no card data in application logs

### Req 4 — Encrypt Transmission
- [ ] All payment data transmitted over TLS 1.2+
- [ ] No fallback to SSL or early TLS versions

### Req 8 — Identify and Authenticate Access
- [ ] Multi-factor authentication for admin/privileged access
- [ ] Passwords expire every 90 days for privileged accounts
- [ ] Account lockout after 6 failed attempts

### Req 10 — Logging and Monitoring
- [ ] All access to cardholder data is logged
- [ ] Logs are tamper-proof (write-once or hash-chained)
- [ ] Logs retained for minimum 12 months
```

### Step 2d — SOX Assessment

```bash
# Financial data integrity
rg "balance\|amount\|transaction\|ledger\|journal" src/ -i | \
  rg -v "test\|spec" | head -20

# Audit trail for financial changes
rg "updateBalance\|adjustAmount\|writeOff\|reconcile" src/ -i | \
  rg -v "auditLog\|log\|track" | head -10  # missing audit trail

# Change management — who can modify financial records
rg "@Roles.*FINANCE\|@HasPermission.*WRITE_FINANCIAL\|@Authorize.*financial" \
  src/ -i | head -10
```

### Step 3 — Generate Compliance Gap Report

```markdown
# Compliance Gap Report

**Project:** [auto-detected]
**Date:** YYYY-MM-DD
**Framework(s):** GDPR + HIPAA
**Industry:** Healthcare SaaS
**Generated by:** /tw-compliance-audit | v0.5.0

---

## Executive Summary

| Requirement | Status | Gap Count | Risk |
|---|---|---|---|
| GDPR Art. 17 (Right to Erasure) | PARTIAL | 3 gaps | HIGH |
| GDPR Art. 7 (Consent) | MISSING | 5 gaps | CRITICAL |
| GDPR Art. 33 (Breach Notification) | MISSING | 2 gaps | HIGH |
| HIPAA — Audit Controls | PARTIAL | 4 gaps | HIGH |
| HIPAA — Automatic Logoff | MISSING | 1 gap | MEDIUM |

**Overall compliance posture: NOT READY**
Critical gaps must be resolved before processing EU personal data or PHI.

---

## CRITICAL Gaps — Block Data Processing

### GDPR — No Consent Management
No consent recording mechanism found in the codebase. Under GDPR Art. 7, processing
personal data without documented consent is illegal and can result in fines up to
4% of global annual turnover.

**Required tests to add:**
1. POST /api/consent — records consent with timestamp and terms version
2. DELETE /api/consent — withdraws consent and stops processing
3. GET /api/consent — returns current consent status

**Suggested implementation:** Add `UserConsent` entity with `acceptedAt`, `version`,
`scope[]` fields. Every data processing operation must check consent before executing.

---

## HIGH Gaps

### GDPR — Right to Erasure Incomplete
`deleteUser()` found in `UserService` but:
- Does not cascade to `orders` table (foreign key without cascade delete)
- Does not notify downstream services (notification-service, analytics-service)
- No audit log of the deletion

---

## Tests to Add (Priority Order)

1. Consent recording and withdrawal (GDPR Art. 7)
2. PHI audit log completeness (HIPAA §164.312)
3. Data cascade deletion (GDPR Art. 17)
4. Session timeout (HIPAA §164.312)
5. Breach detection alert (GDPR Art. 33)

## Next Steps

1. Review this report with the legal/compliance team
2. Assign CRITICAL gaps as P0 stories in the backlog
3. Re-run `/tw-compliance-audit` after gaps are addressed
4. Schedule a formal compliance audit with a certified auditor for final certification
```

## Examples

### Example 1 — GDPR assessment for a SaaS product

```
/tw-compliance-audit framework=gdpr industry=saas
```

### Example 2 — HIPAA checklist for a healthcare app

```
/tw-compliance-audit framework=hipaa industry=healthcare mode=checklist
```

### Example 3 — Multi-framework for a fintech

```
/tw-compliance-audit framework=gdpr,pci-dss industry=finance mode=full
```

### Example 4 — Export for GRC tool

```
/tw-compliance-audit framework=iso27001 output=csv
```

## Dependencies

- Source code accessible in working directory (for `mode=assess` and `mode=full`)
- No additional tools required for static analysis
- For accurate assessment, access to database schema and API documentation is useful

## Notes

- This skill provides a technical compliance baseline — it does not replace a certified compliance audit
- Findings should be reviewed by a legal/compliance professional before making compliance claims to clients
- Some requirements (e.g., physical access controls, business continuity plans) cannot be assessed from code
- GDPR and HIPAA have significant overlap — when both apply, use `framework=gdpr,hipaa`
- PCI-DSS requires annual assessment by a Qualified Security Assessor (QSA) for SAQ-D merchants
- Pair with `/tw-security-audit` — many compliance requirements are covered by security controls
