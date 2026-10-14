---
name: java-test-governor
description: Audits JUnit 5 unit test coverage in a Java/Spring Boot repository, maps production classes to test files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: base_ref
    type: string
    required: false
    default: ""
    description: Git ref to diff against (e.g. origin/main). When provided, focuses on changed classes.
  - name: jacoco_xml
    type: string
    required: false
    default: ""
    description: Path to Jacoco XML coverage report (e.g. target/site/jacoco/jacoco.xml). Enables per-class coverage signals.
  - name: test_results_dir
    type: string
    required: false
    default: ""
    description: Directory containing Surefire/Failsafe JUnit XML output for failing test detection.
  - name: build_tool
    type: string
    required: false
    default: ""
    description: "Build tool: 'maven' or 'gradle'. Auto-detected from pom.xml or build.gradle."
tags:
  - java
  - spring-boot
  - junit5
  - mockito
  - jacoco
  - testing
  - coverage
  - governance
invocation: tw-java-test-governor
---

# java-test-governor

## Description

Audits JUnit 5 unit test coverage in a Java/Spring Boot repository. Maps every production
class to its test file status, classifies gaps by severity (CRITICAL / HIGH / MEDIUM / LOW),
determines the correct action per class (create-test / update-test / no-change / no-test-needed),
and outputs a structured governance report. Integrates with Jacoco XML coverage and git diffs
to focus the analysis on changed code.

**Stack:** Java 11+ / Spring Boot / JUnit 5 / Mockito / WireMock / AssertJ / Jacoco

Use this skill before `/tw-java-test-remediator` — the governor produces the report,
the remediator turns it into code.

## When to Use

- Before a release or sprint review in a Java/Spring Boot project
- After onboarding a new Java service to the toolkit
- When Jacoco coverage drops below team thresholds
- To understand which Spring components (services, repositories, controllers) lack tests

Triggers: "audit Java test coverage", "check Spring Boot tests", "Java governance report",
"which Java classes have no tests".

## Instructions

### Step 1 — Detect Build Tool and Run Tests

```bash
# Maven
ls pom.xml && echo "maven"
mvn test jacoco:report -q || true
# Coverage report: target/site/jacoco/jacoco.xml
# Test results: target/surefire-reports/

# Gradle
ls build.gradle build.gradle.kts && echo "gradle"
./gradlew test jacocoTestReport || true
# Coverage report: build/reports/jacoco/test/jacocoTestReport.xml
# Test results: build/test-results/test/
```

### Step 2 — Inventory Production Classes

```bash
# All production Java/Kotlin classes (exclude test sources)
rg -l "" --glob "src/main/**/*.java" --glob "src/main/**/*.kt" | sort

# Classify by Spring stereotype
rg "@Service|@Component|@Repository|@RestController|@Controller" src/main/ -l
rg "@Configuration|@Bean" src/main/ -l
```

For each class, detect:
- **Spring stereotype**: `@Service`, `@Repository`, `@RestController`, `@Component`
- **Complexity indicators**: number of methods, `@Autowired` dependencies, branches
- **Domain classification**: service layer, repository, controller, domain entity, utility

### Step 3 — Inventory Test Classes

```bash
# All test classes
rg -l "" --glob "src/test/**/*Test.java" --glob "src/test/**/*Tests.java" \
   --glob "src/test/**/*Spec.java" --glob "src/test/**/*IT.java" | sort

# Classify test type
rg "@ExtendWith\(MockitoExtension|@MockBean|@Mock\b" src/test/ -l  # unit tests
rg "@SpringBootTest|@WebMvcTest|@DataJpaTest" src/test/ -l         # integration/slice tests
rg "@Testcontainers|@Container" src/test/ -l                       # integration with containers
```

**Unit test** — most of these are true:
- Name ends with `Test.java` (not `IT.java`)
- Uses `@ExtendWith(MockitoExtension.class)` or `@InjectMocks` / `@Mock`
- Does not load Spring context (`@SpringBootTest` absent)
- Executes in < 1 second

**Spring slice / integration test** — uses:
- `@WebMvcTest` (controller layer)
- `@DataJpaTest` (repository layer)
- `@SpringBootTest` (full context)

Out of scope: integration tests (IT suffix) are excluded from gap analysis unless the user
explicitly expands the task.

### Step 4 — Map Classes to Tests

For each production class, find its test:
- `OrderService.java` → `OrderServiceTest.java` (same package in test source tree)
- `OrderRepository.java` → `OrderRepositoryTest.java`
- Apply fuzzy match for non-standard naming: `OrderServiceImplTest`, `OrderServiceUnitTest`

Parse Jacoco XML if provided:
```xml
<!-- jacoco.xml structure -->
<package name="com/example/orders">
  <class name="OrderService" sourcefilename="OrderService.java">
    <counter type="LINE" missed="4" covered="28"/>
    <counter type="BRANCH" missed="2" covered="8"/>
  </class>
</package>
```

### Step 5 — Classify and Prioritize

**Coverage Priority Order:**

1. `@Service`, `@Component` classes with `@Transactional`, conditional logic, external calls
2. `@RestController` with validation, authorization, error handling
3. Domain entities with business methods (not plain JPA entities with only getters/setters)
4. `@Repository` with custom JPQL/native queries
5. Utility/helper classes with branching logic

**Do NOT prioritize:**
- Plain JPA entity classes (only `@Column`, `@Id`, getters/setters)
- `@Configuration` classes with only `@Bean` definitions
- `*Application.java` main class
- Simple exception classes (`extends RuntimeException` with no logic)
- DTOs / Records with no behavior

### Step 6 — Generate Governance Report

Same 7-section structure as `ts-test-governor` adapted for Java:

```markdown
# Java Unit Test Governance Report

**Generated:** YYYY-MM-DD HH:MM:SS
**Skill:** /tw-java-test-governor | v0.4.0
**Build tool:** [maven|gradle]
**Module:** [artifact-id from pom.xml or project name from build.gradle]

## Executive Summary
- **Classes analyzed:** N
- **With unit tests:** X (Y%)
- **Jacoco line coverage:** Z% (if available)
- **Overall decision:** [CREATE TESTS | FIX TESTS FIRST | NO ACTION NEEDED]
- **Primary risk:** [one sentence]

## Findings

| Area | Class | Finding | Severity | Action |
|---|---|---|---|---|
| Service | OrderService | Business logic, 12 methods, @Transactional — no test | CRITICAL | create-test |
| Repository | OrderRepository | 3 custom @Query methods — no test | HIGH | create-test |
| Controller | OrderController | @PreAuthorize on 2 methods — authorization untested | HIGH | create-test |

## Impacted Classes

| Class | Stereotype | Line Coverage | Test File | Decision |
|---|---|---|---|---|
| OrderService | @Service | 0% (no test) | — | create-test |
| PaymentService | @Service | 87% | PaymentServiceTest | no-change |

## Recommendations

**Priority 1 (CRITICAL):** Create tests for @Service classes with zero coverage...
**Priority 2 (HIGH):** Add tests for @RestController authorization paths...

Would you like me to: 1) generate tests with /tw-java-test-remediator,
2) focus on a specific package, 3) add Jacoco thresholds to the build?
```

### Step 7 — Save Report

```bash
filename="TEST_GOVERNANCE_REPORT_$(date +%Y-%m-%d_%H-%M-%S).md"
```

## Examples

### Example 1 — Full audit of a Spring Boot repo

```
/tw-java-test-governor
```

### Example 2 — Diff-focused audit with Jacoco coverage

```
/tw-java-test-governor base_ref=origin/main jacoco_xml=target/site/jacoco/jacoco.xml
```

### Example 3 — Gradle project with test results

```
/tw-java-test-governor build_tool=gradle test_results_dir=build/test-results/test/
```

## Dependencies

- Java project with `pom.xml` or `build.gradle`
- Maven or Gradle installed and executable
- `ripgrep` (`rg`) for class scanning
- Jacoco plugin configured in build file (optional but recommended)

## Notes

- Spring slice tests (`@WebMvcTest`, `@DataJpaTest`) are not unit tests but are valuable;
  this skill reports them separately and does not include them in unit gap analysis
- Kotlin Spring projects are supported — scan `.kt` files in addition to `.java`
- For multi-module Maven projects, run from the parent POM directory
