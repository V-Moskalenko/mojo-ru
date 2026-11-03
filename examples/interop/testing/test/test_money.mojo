from money import parse_cents, split_bill
from std.random import random_si64, seed
from std.testing import assert_equal, assert_raises, assert_true, TestSuite


def test_parse_whole_rubles() raises:
    assert_equal(parse_cents("12"), 1200)


def test_parse_with_kopecks() raises:
    assert_equal(parse_cents("12.50"), 1250)
    assert_equal(parse_cents("0.05"), 5)
    assert_equal(parse_cents(" 7.00 "), 700)


def test_parse_rejects_one_digit() raises:
    with assert_raises(contains="две цифры"):
        _ = parse_cents("12.5")
    with assert_raises(contains="две цифры"):
        _ = parse_cents("12.-5")


def test_parse_rejects_negative() raises:
    with assert_raises(contains="отрицательной"):
        _ = parse_cents("-3.00")


def test_parse_rejects_negative_kopecks() raises:
    with assert_raises(contains="отрицательной"):
        _ = parse_cents("-0.50")
    with assert_raises(contains="отрицательной"):
        _ = parse_cents(" -0.50")


def test_parse_rejects_what_int_forgives() raises:
    for text in ["+5", "1_000", "", ".50"]:
        with assert_raises(contains="только цифры"):
            _ = parse_cents(text)


def test_parse_rejects_overflow() raises:
    with assert_raises(contains="слишком большая"):
        _ = parse_cents("9223372036854775807")


def test_split_even() raises:
    assert_equal(split_bill(900, 3), [300, 300, 300])


def test_split_with_remainder() raises:
    assert_equal(split_bill(1000, 3), [334, 333, 333])


def test_split_rejects_bad_input() raises:
    with assert_raises(contains="некому"):
        _ = split_bill(100, 0)
    with assert_raises(contains="отрицательной"):
        _ = split_bill(-100, 3)


def test_split_keeps_every_kopeck() raises:
    seed(42)
    for _ in range(1000):
        var total = Int(random_si64(0, 1_000_000))
        var people = Int(random_si64(1, 50))
        var parts = split_bill(total, people)

        var paid = 0
        for part in parts:
            paid += part
        var inputs = String(total, " на ", people)
        assert_equal(paid, total, msg=inputs)
        assert_true(parts[0] - parts[len(parts) - 1] <= 1, msg=inputs)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
