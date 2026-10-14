---
name: security-first
description: Behavioral rule that instructs AI assistants to surface security implications proactively — before implementing features that handle sensitive data, before suggesting third-party integrations, and before any code that touches auth, payments, PII, or external APIs.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: full
  codex: partial
tags:
  - security
  - owasp
  - pii
  - auth
  - mindset
  - rule
---

# security-first — Rule Fragment

Add this fragment to `CLAUDE.md` or `.cursorrules` to activate security-aware behavior.

---

## Rule Fragment (paste into CLAUDE.md)

```markdown
## Security-First Behavior

When implementing any of the following, surface security implications BEFORE writing code:

**Triggers for security review:**
- Any endpoint or function that handles authentication, authorization, or sessions
- Any code that reads, writes, or transmits personal data (name, email, phone, address, SSN, DOB)
- Any code that processes payments, card data, or financial transactions
- Any new third-party integration (external API, SDK, library)
- Any query construction that includes user-provided input
- Any file upload, download, or file system access
- Any cryptographic operation (hashing, encryption, signing)

**What to surface before implementing:**
1. Which OWASP Top 10 categories apply to this feature?
2. Is user input being validated and sanitized before use?
3. Are secrets/credentials going into environment variables (not code)?
4. Does this endpoint need authentication? Role-based authorization?
5. Will this log or expose sensitive data in error messages?

**Code patterns to flag immediately:**
- String concatenation into SQL queries → parameterize
- Hardcoded passwords, API keys, or secrets → use env vars
- MD5 or SHA1 for passwords → use bcrypt, argon2, or scrypt
- `cors()` without origin restriction → restrict to known origins
- JWT without expiration (`expiresIn`) → add expiration
- Logging request bodies without masking PII → mask sensitive fields

**Never do without explicit acknowledgment:**
- Store passwords in plaintext
- Log credit card numbers, SSNs, or passwords (even hashed)
- Disable TLS verification (`NODE_TLS_REJECT_UNAUTHORIZED=0`) in non-test code
- Use `eval()` on user input
- Trust user-provided IDs for authorization without verification

**When a security concern is found:**
Report it inline — do not silently skip it:
"⚠️ Security note: [description of concern] — [suggested fix]"

Then continue with the implementation using the secure pattern.
```

---

## What This Rule Changes

**Without this rule:**
```typescript
// AI implements as requested — no security flags
app.post('/api/users/search', async (req, res) => {
  const users = await db.query(`SELECT * FROM users WHERE name = '${req.body.name}'`);
  res.json(users);
});
```

**With this rule:**
```
⚠️ Security note: String interpolation of req.body.name into a SQL query creates
an SQL injection vulnerability (OWASP A03:2021). Using a parameterized query instead.
```
```typescript
app.post('/api/users/search', async (req, res) => {
  const users = await db.query('SELECT * FROM users WHERE name = $1', [req.body.name]);
  res.json(users);
});
```

---

## Scope

This rule applies to:
- New feature implementation
- Code reviews and PR feedback
- Refactoring suggestions
- Third-party library recommendations

This rule does NOT apply to:
- Test files (where hardcoded test credentials are acceptable)
- Documentation examples (clearly marked as examples)
- `*.example` and `*.template` files

---

## Pairing

Add alongside `spec-first` for maximum QA coverage:
```markdown
<!-- CLAUDE.md -->
<!-- Load toolkit rules -->
<!-- See .ai/toolkit/rules/spec-first/rule.md -->
<!-- See .ai/toolkit/rules/security-first/rule.md -->
```

Use `/tw-security-audit` to run an automated scan.
Use `/tw-compliance-audit` to check regulatory requirements.
