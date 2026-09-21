import pytest

from src.calculator import add, divide, modulo, multiply, power, subtract


def test_add():
    assert add(2, 3) == 5


def test_subtract():
    assert subtract(5, 3) == 2
    assert subtract(3, 5) == -2
    assert subtract(3, 3) == 0


def test_multiply():
    assert multiply(2, 3) == 6
    assert multiply(-2, 3) == -6
    assert multiply(0, 3) == 0
    assert multiply(1.5, 2) == 3.0


def test_divide():
    assert divide(6, 3) == 2


def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(6, 0)


def test_modulo():
    assert modulo(7, 3) == 1


def test_modulo_by_zero():
    with pytest.raises(ZeroDivisionError):
        modulo(7, 0)


def test_power():
    assert power(2, 3) == 8


def test_power_zero_exponent():
    assert power(5, 0) == 1
