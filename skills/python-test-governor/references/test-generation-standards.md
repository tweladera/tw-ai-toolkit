# Test Generation Standards

When generating unit tests for Python code, follow these standards to ensure maintainability, readability, and effectiveness.

---

## Framework Selection

### pytest (Preferred)

Use pytest when:
- Project already uses pytest
- Need fixtures and parameterization
- Want cleaner, more Pythonic syntax
- Project has `pytest.ini` or uses `pytest` in CI

```python
# pytest style
def test_process_data_success():
    # Arrange
    processor = DataProcessor()
    data = {"id": 1, "name": "test"}

    # Act
    result = processor.process(data)

    # Assert
    assert result is not None
    assert result["id"] == 1
    assert result["name"] == "test"
```

### unittest (Standard Library)

Use unittest when:
- Project uses standard library only
- No pytest in dependencies
- Existing tests use `TestCase` pattern
- Need compatibility with test discovery tools

```python
# unittest style
import unittest

class TestDataProcessor(unittest.TestCase):
    def test_process_data_success(self):
        # Arrange
        processor = DataProcessor()
        data = {"id": 1, "name": "test"}

        # Act
        result = processor.process(data)

        # Assert
        self.assertIsNotNone(result)
        self.assertEqual(result["id"], 1)
        self.assertEqual(result["name"], "test")
```

---

## Test Structure

### Arrange / Act / Assert Pattern

Always structure tests in three clear sections:

```python
def test_calculate_total_with_discount():
    # Arrange - Set up test data and dependencies
    calculator = PriceCalculator()
    items = [
        {"price": 100, "quantity": 2},
        {"price": 50, "quantity": 1}
    ]
    discount = 0.1

    # Act - Execute the behavior being tested
    total = calculator.calculate_total(items, discount)

    # Assert - Verify the outcome
    assert total == 225.0  # (200 + 50) * 0.9
```

### One Behavior Per Test

Each test should verify a single behavior or scenario:

```python
# Good - focused tests
def test_process_valid_data():
    """Process returns transformed data for valid input"""
    pass

def test_process_empty_data():
    """Process returns empty result for empty input"""
    pass

def test_process_invalid_data_raises_error():
    """Process raises ValueError for invalid input"""
    pass

# Bad - multiple behaviors
def test_process():
    """Test all processing scenarios"""  # Too broad!
    pass
```

---

## Naming Conventions

### Test Function Names

Use descriptive names that indicate:
1. What is being tested
2. The scenario/condition
3. Expected outcome

```python
# Good naming
def test_parse_date_with_valid_iso_format():
def test_parse_date_with_invalid_format_raises_error():
def test_calculate_discount_when_amount_exceeds_threshold():

# Bad naming
def test_parse():
def test_1():
def test_edge_case():
```

### Test File Names

Follow pytest/unittest conventions:
- `test_*.py` (pytest standard)
- `*_test.py` (alternative)

Match production module names:
- Production: `data_processor.py`
- Test: `test_data_processor.py`

---

## Mocking and Patching

### Use unittest.mock or pytest-mock

Mock external dependencies, not the code under test:

```python
from unittest.mock import Mock, patch

def test_fetch_user_data_calls_api():
    # Arrange
    with patch('module.requests.get') as mock_get:
        mock_get.return_value.json.return_value = {"id": 1, "name": "Alice"}
        client = UserClient()

        # Act
        result = client.fetch_user(1)

        # Assert
        assert result["name"] == "Alice"
        mock_get.assert_called_once_with("https://api.example.com/users/1")
```

### When to Mock

**DO mock**:
- External API calls
- Database connections
- File I/O operations
- Time-dependent functions (`datetime.now()`)
- Random number generators

**DON'T mock**:
- The class/function under test
- Simple data structures
- Pure functions without side effects
- Standard library functions (unless I/O)

---

## Fixtures (pytest)

### Use Fixtures for Common Setup

```python
import pytest

@pytest.fixture
def sample_data():
    """Provide sample data for tests"""
    return [
        {"id": 1, "name": "Alice"},
        {"id": 2, "name": "Bob"}
    ]

@pytest.fixture
def processor():
    """Provide a DataProcessor instance"""
    return DataProcessor()

def test_process_batch(processor, sample_data):
    result = processor.process_batch(sample_data)
    assert len(result) == 2
```

### Fixture Scope

Choose appropriate scope:
- `function` (default) - New instance per test
- `class` - Shared across test class
- `module` - Shared across module
- `session` - Shared across test session

```python
@pytest.fixture(scope="module")
def database_connection():
    """Expensive setup, reuse across module"""
    conn = create_connection()
    yield conn
    conn.close()
```

---

## Parameterized Tests

### Use for Multiple Input/Output Scenarios

**pytest parametrize**:
```python
import pytest

@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("", ""),
    (None, None)
])
def test_to_upper(input, expected):
    result = to_upper(input)
    assert result == expected
```

**unittest subTest**:
```python
class TestToUpper(unittest.TestCase):
    def test_to_upper_various_inputs(self):
        test_cases = [
            ("hello", "HELLO"),
            ("world", "WORLD"),
            ("", ""),
        ]
        for input_val, expected in test_cases:
            with self.subTest(input=input_val):
                result = to_upper(input_val)
                self.assertEqual(result, expected)
```

### When to Parametrize

**Good candidates**:
- Same logic, different inputs
- Boundary value testing
- Format validation (email, phone, etc.)
- Mathematical calculations with known outputs

**Bad candidates**:
- Tests with different setup requirements
- Tests with different assertions
- Unrelated test scenarios

---

## Exception Testing

### pytest raises:
```python
import pytest

def test_divide_by_zero_raises_error():
    calculator = Calculator()
    with pytest.raises(ValueError, match="Cannot divide by zero"):
        calculator.divide(10, 0)
```

### unittest assertRaises:
```python
def test_divide_by_zero_raises_error(self):
    calculator = Calculator()
    with self.assertRaises(ValueError) as context:
        calculator.divide(10, 0)
    self.assertIn("Cannot divide by zero", str(context.exception))
```

---

## Assertions

### Use Specific Assertions

**pytest assertions**:
```python
# Good - specific assertions
assert result is not None
assert len(items) == 3
assert "key" in data
assert value > 0
assert isinstance(obj, MyClass)

# Bad - too generic
assert result  # What are we checking?
assert True  # Meaningless
```

**unittest assertions**:
```python
# Good - specific assertions
self.assertIsNotNone(result)
self.assertEqual(len(items), 3)
self.assertIn("key", data)
self.assertGreater(value, 0)
self.assertIsInstance(obj, MyClass)

# Bad - too generic
self.assertTrue(result)  # What property?
self.assertTrue(True)  # Meaningless
```

---

## Test Data

### Use Realistic but Minimal Data

```python
# Good - minimal but realistic
def test_create_user():
    user_data = {
        "email": "test@example.com",
        "name": "Test User"
    }
    user = create_user(user_data)
    assert user.email == "test@example.com"

# Bad - overly complex
def test_create_user():
    user_data = {
        "email": "test@example.com",
        "name": "Test User",
        "address": "123 Main St",
        "city": "Anytown",
        "state": "CA",
        "zip": "12345",
        # ... 20 more fields
    }
    # Only testing email!
```

### Deterministic Data

Always use deterministic test data:

```python
# Good - deterministic
def test_process_timestamp():
    fixed_time = datetime(2024, 1, 1, 12, 0, 0)
    with patch('module.datetime') as mock_datetime:
        mock_datetime.now.return_value = fixed_time
        result = process_timestamp()
        assert result == "2024-01-01 12:00:00"

# Bad - non-deterministic
def test_process_timestamp():
    result = process_timestamp()  # Uses current time
    assert result is not None  # Weak assertion
```

---

## Test Independence

### Each Test Should Be Isolated

```python
# Good - independent tests
def test_add_item():
    cart = ShoppingCart()
    cart.add_item("apple")
    assert len(cart.items) == 1

def test_remove_item():
    cart = ShoppingCart()
    cart.add_item("apple")
    cart.remove_item("apple")
    assert len(cart.items) == 0

# Bad - tests depend on order
cart = ShoppingCart()  # Shared state!

def test_add_item():
    cart.add_item("apple")
    assert len(cart.items) == 1

def test_remove_item():
    # Depends on previous test running first!
    cart.remove_item("apple")
    assert len(cart.items) == 0
```

---

## Documentation

### Clear Docstrings for Complex Tests

```python
def test_complex_business_logic():
    """
    Verify that the discount calculation correctly handles:
    - Base price calculation from items
    - Volume discount when quantity > 10
    - Membership discount of 15%
    - Both discounts should not stack (use max)
    """
    # Test implementation
```

---

## Code Quality

### Follow Project Style

- Match existing test patterns
- Use same assertion library (pytest vs unittest)
- Follow same fixture/setup patterns
- Maintain same file organization

### Keep Tests Simple

```python
# Good - simple and clear
def test_filter_active_users():
    users = [
        User(name="Alice", active=True),
        User(name="Bob", active=False),
        User(name="Charlie", active=True)
    ]
    active = filter_active_users(users)
    assert len(active) == 2
    assert all(u.active for u in active)

# Bad - overly clever
def test_filter_active_users():
    users = [User(f"U{i}", bool(i%2)) for i in range(100)]
    assert len(filter_active_users(users)) == sum(1 for u in users if u.active)
```

---

## Checklist for Generated Tests

- [ ] Uses pytest or unittest based on project
- [ ] Follows Arrange/Act/Assert pattern
- [ ] Has descriptive test name
- [ ] Tests one behavior per function
- [ ] Uses appropriate mocks for external dependencies
- [ ] Has specific, meaningful assertions
- [ ] Uses fixtures appropriately (pytest)
- [ ] Is independent from other tests
- [ ] Uses deterministic test data
- [ ] Includes docstring if logic is complex
- [ ] Matches project code style
- [ ] Would actually catch regressions
