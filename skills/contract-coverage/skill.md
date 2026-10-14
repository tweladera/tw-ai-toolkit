---
name: contract-coverage
description: Scans a repository for inter-service communication (HTTP, messaging, events), maps consumer-provider relationships, detects missing contract tests, and generates Pact interaction stubs for uncovered integrations.
status: stable
version_added: v0.2.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: mode
    type: string
    required: false
    default: "detect"
    description: "'detect' to report missing contracts only. 'generate' to also create Pact interaction stubs for uncovered integrations."
  - name: path
    type: string
    required: false
    default: ""
    description: Directory to scan (defaults to repo root). Use to focus on a specific service or module.
  - name: focus
    type: string
    required: false
    default: ""
    description: "Service name or path to focus the report on (e.g. 'payment-service'). Shows only contracts where this service is consumer or provider."
tags:
  - contract-testing
  - pact
  - integration
  - microservices
  - qa
  - cdc
invocation: tw-contract-coverage
---

# contract-coverage

## Description

Surfaces the integration blind spots that unit tests never catch. Scans the codebase for all
points where this service communicates with external systems — HTTP clients, message producers,
message consumers, and event subscriptions — then checks whether contract tests (Pact or equivalent)
exist for each integration point.

**Why this matters for SDET teams:** Unit test coverage at 90% says nothing about whether
Service A and Service B can actually talk to each other. Contract tests are the layer between
unit and end-to-end that makes microservice integration visible and automatable.

**Scope:** Detection and stub generation only. This skill does NOT run a Pact broker,
deploy Pact servers, or manage provider states. It surfaces what is missing and gives
you the starting point for the Pact workflow.

## When to Use

- After `/tw-ts-test-governor` or `/tw-python-test-governor` — as the next layer of coverage
- Before a release involving multiple services
- When a new API endpoint or event schema is added
- When integration failures appear in staging but unit tests pass
- When onboarding a new microservice to understand its dependency map

Triggers: user says "what services does this depend on", "where are our contract tests",
"we have an integration failure but tests pass", "map our service dependencies".

## Instructions

### Step 1 — Scan for Outbound HTTP Communication

Search for HTTP client usage patterns:

```bash
# TypeScript / JavaScript
rg -l "axios|fetch|got|node-fetch|HttpService|HttpModule|@nestjs/axios" --type ts --type js

# Python
rg -l "requests\.|httpx\.|aiohttp\.|urllib\.request" --type py

# Java
rg -l "RestTemplate|WebClient|FeignClient|OkHttpClient|HttpClient" --type java
```

For each file found, read it and extract:
- **URL patterns**: hardcoded URLs, config keys (`process.env.SERVICE_URL`, `@Value("${service.url}")`)
- **HTTP methods used**: GET, POST, PUT, PATCH, DELETE
- **Request shape**: what the call sends (body schema, headers, query params)
- **Response shape**: what the caller expects to receive (mapped fields, status codes handled)
- **Error handling**: does the caller handle 4xx, 5xx, timeouts?

### Step 2 — Scan for Message Producer Communication

```bash
# Kafka producers
rg -l "KafkaProducer|producer\.send|kafkaClient\.send|@nestjs/microservices" --type ts --type py --type java

# RabbitMQ
rg -l "amqplib|pika\.BlockingConnection|RabbitTemplate|channel\.publish" --type ts --type py --type java

# AWS SQS / SNS / EventBridge
rg -l "SQSClient|SNSClient|EventBridgeClient|boto3\.client\('sqs'\)" --type ts --type py --type java
```

For each, extract: topic/queue/exchange name, message schema (fields published), event type.

### Step 3 — Scan for Message Consumer Communication

```bash
rg -l "@MessagePattern|@EventPattern|@KafkaListener|consumer\.subscribe|pika.*channel\.basic_consume" \
  --type ts --type py --type java
```

For each, extract: topic/queue subscribed, expected message schema, handler behavior.

### Step 4 — Build Consumer-Provider Map

Construct a dependency map from the findings:

```
This service (CONSUMER) depends on:
  - [ServiceA] via HTTP GET /api/orders/{id}         → response: Order object
  - [ServiceB] via Kafka topic "payment.confirmed"   → message: PaymentEvent

This service (PROVIDER) exposes:
  - HTTP POST /api/invoices                          → consumed by [unknown — detect from callers]
  - Kafka topic "invoice.created"                    → consumers [unknown — document for discovery]
```

When the provider name is unknown (only URL or topic name available), mark as `[inferred]`
and include the URL/topic as the identifier.

### Step 5 — Check for Existing Contract Tests

```bash
# Pact files (JSON contracts)
rg -l "\.pact\.json|pact\.js|@pact-foundation/pact|pact-python|au\.com\.dius\.pact" \
  --type ts --type js --type py --type java

# Spring Cloud Contract
rg -l "@AutoConfigureStubRunner|stubRunnerPort|ContractVerifierTest" --type java

# Any file named *.pact.* or *contract*
find . -name "*.pact.*" -o -name "*contract*.spec.*" -o -name "*contract*.test.*" 2>/dev/null
```

For each contract test found, map it to the integration point it covers.

### Step 6 — Generate Contract Coverage Matrix

```markdown
## Contract Coverage Matrix

| Integration | Type | Consumer | Provider | Contract Test | Status | Risk |
|---|---|---|---|---|---|---|
| GET /api/orders/{id} | HTTP | this-service | order-service | None found | MISSING | HIGH |
| POST /api/payments | HTTP | this-service | payment-service | payments.pact.spec.ts | COVERED | — |
| payment.confirmed | Kafka consume | this-service | payment-service | None found | MISSING | HIGH |
| invoice.created | Kafka produce | unknown consumers | this-service | None found | UNVERIFIED | MEDIUM |
```

**Status values:**
- `COVERED` — contract test found and maps to this integration
- `MISSING` — integration point found, no contract test
- `UNVERIFIED` — this service is a provider; consumers are unknown or unchecked
- `STALE` — contract test exists but targets a different URL/schema than current code

**Risk classification:**
- `HIGH` — synchronous HTTP call or consumed message with no contract; failure is silent until runtime
- `MEDIUM` — produced message or event; breaks consumers you may not own
- `LOW` — internal integration within the same bounded context or deployment unit

### Step 7 — Report Summary

```markdown
## Contract Coverage Summary

**Service scanned:** [path or name]
**Integration points found:** N total
  - HTTP outbound: X
  - Message produced: X
  - Message consumed: X

**Contract coverage:** Y/N (Z%)
  - COVERED: Y
  - MISSING: A (HIGH risk: B, MEDIUM risk: C)
  - UNVERIFIED: D

**Biggest risks:**
1. [Integration] — [reason risk is high]
2. [Integration] — [reason risk is high]
```

### Step 8 — Generate Pact Stubs (if mode=generate)

For each `MISSING` or `STALE` integration with risk HIGH or MEDIUM, generate a Pact
interaction stub matched to the detected stack.

**TypeScript / Jest (Pact JS):**
```typescript
// [consumer]-[provider].pact.spec.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
const { like, regex } = MatchersV3;

const provider = new PactV3({
  consumer: '[consumer-name]',
  provider: '[provider-name]',
});

describe('[Consumer] → [Provider] contract', () => {
  it('[HTTP method] [path] returns expected shape', () => {
    return provider
      .given('[provider state]')
      .uponReceiving('[interaction description]')
      .withRequest({ method: '[METHOD]', path: '[PATH]', /* headers, body */ })
      .willRespondWith({
        status: 200,
        body: like({ /* expected response shape from Step 1 */ }),
      })
      .executeTest(async (mockServer) => {
        // TODO: call your service's HTTP client against mockServer.url
        // and assert the result
      });
  });
});
```

**Python (pact-python):**
```python
# test_[consumer]_[provider]_pact.py
import pytest
from pact import Consumer, Provider

@pytest.fixture
def pact():
    return Consumer('[consumer-name]').has_pact_with(
        Provider('[provider-name]'),
        pact_dir='pacts'
    )

def test_[interaction_name](pact):
    expected = { /* expected response shape */ }
    (pact
     .given('[provider state]')
     .upon_receiving('[interaction description]')
     .with_request('[METHOD]', '[PATH]')
     .will_respond_with(200, body=Like(expected)))
    with pact:
        # TODO: call your service's HTTP client
        pass
```

For Kafka message contracts, generate the message schema as a JSON file:
```json
{
  "consumer": "[consumer-name]",
  "provider": "[provider-name]",
  "interactions": [{
    "description": "[event description]",
    "providerStates": [{ "name": "[state]" }],
    "type": "Asynchronous/Messages",
    "contents": { /* message schema from Step 2 or 3 */ }
  }]
}
```

Stubs are saved to:
```
contract-tests/[consumer]-[provider]/[interaction-name].pact.spec.[ts|py]
```

## Examples

### Example 1 — Detect missing contracts in full repo

```
/tw-contract-coverage
```

### Example 2 — Detect + generate stubs

```
/tw-contract-coverage mode=generate
```

### Example 3 — Focus on a specific service path

```
/tw-contract-coverage path=src/payment focus=payment-service mode=generate
```

### Example 4 — After test governor (full QA flow)

```
# Layer 1: unit coverage
/tw-ts-test-governor

# Layer 2: contract coverage
/tw-contract-coverage mode=generate

# Layer 3: spec-first for next feature
/tw-exec-spec-generator story=docs/stories/next-feature.md
```

## Dependencies

- `ripgrep` (`rg`) installed — required for scanning
- For `mode=generate` with TypeScript: `@pact-foundation/pact` installable in the project
- For `mode=generate` with Python: `pact-python` installable in the project
- For `mode=generate` with Java: Spring Cloud Contract or au.com.dius.pact in build config

## Notes

- This skill detects and generates stubs — running the Pact provider verification requires
  a running provider and is out of scope (do that in CI with `pact-provider-verifier`)
- When provider is `[inferred]`, manually review and replace with the actual service name
  before committing stubs
- Pact stubs generated are starting points — the `executeTest` body requires implementation
- Contract tests generated here should be committed and run in CI to generate Pact JSON files
