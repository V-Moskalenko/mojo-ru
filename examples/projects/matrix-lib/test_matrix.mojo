from std.math import nan
from matrix import Matrix, matmul, matmul_naive
from std.testing import assert_equal, assert_raises, assert_true, TestSuite


def test_small_known_product() raises:
    var a = Matrix(2, 2)
    var b = Matrix(2, 2)
    a[0, 0] = 1.0
    a[0, 1] = 2.0
    a[1, 0] = 3.0
    a[1, 1] = 4.0
    b[0, 0] = 5.0
    b[0, 1] = 6.0
    b[1, 0] = 7.0
    b[1, 1] = 8.0
    var c = a @ b
    assert_equal(c[0, 0], 19.0)
    assert_equal(c[0, 1], 22.0)
    assert_equal(c[1, 0], 43.0)
    assert_equal(c[1, 1], 50.0)


def test_identity_changes_nothing() raises:
    var a = Matrix.random(37, 37, 7)
    assert_equal(a.max_abs_diff(matmul(a, Matrix.identity(37))), 0.0)
    assert_equal(a.max_abs_diff(matmul(Matrix.identity(37), a)), 0.0)


def test_matches_naive_on_awkward_sizes() raises:
    # размеры, не кратные ни 4 строкам, ни ширине полосы
    for m in [1, 3, 5, 33]:
        for k in [0, 1, 19]:
            for n in [1, 7, 31, 33, 65]:
                var a = Matrix.random(m, k, m)
                var b = Matrix.random(k, n, n)
                var diff = matmul_naive(a, b).max_abs_diff(matmul(a, b))
                assert_true(
                    diff < 1e-12,
                    msg=String(m, "×", k, " на ", k, "×", n, ": ", diff),
                )


def test_one_thread_equals_many() raises:
    var a = Matrix.random(64, 48, 1)
    var b = Matrix.random(48, 80, 2)
    assert_equal(matmul(a, b).max_abs_diff(matmul(a, b, workers=1)), 0.0)


def test_diff_notices_nan() raises:
    var a = Matrix(1, 2)
    var b = Matrix(1, 2)
    b[0, 1] = nan[DType.float64]()
    assert_true(a.max_abs_diff(b) > 1.0)


def test_shape_mismatch() raises:
    with assert_raises(contains="нельзя умножить"):
        _ = matmul(Matrix(2, 3), Matrix(2, 3))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
