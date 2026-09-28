from std.math import ceildiv
from std.sys import has_accelerator
from std.testing import assert_equal, assert_true, TestSuite

from max.gpu.host import DeviceContext

from fractal import MAX_ITER, escape_time, mandelbrot_cpu, mandelbrot_kernel


def test_points_inside_never_escape() raises:
    assert_equal(escape_time(0, 0), MAX_ITER)
    assert_equal(escape_time(-0.5, 0), MAX_ITER)
    assert_equal(escape_time(-1, 0), MAX_ITER)


def test_points_outside_escape_on_known_step() raises:
    # 2.5 + 0i: уже после первого шага |z|² = 6.25 > 4
    assert_equal(escape_time(2.5, 0), 1)
    # 1 + 1i: z₁ = 1 + i, z₂ = 1 + 3i, |z₂|² = 10 > 4
    assert_equal(escape_time(1, 1), 2)


def test_gpu_matches_cpu() raises:
    comptime if has_accelerator():
        comptime width = 640
        comptime height = 480
        var ctx = DeviceContext()
        var device = ctx.enqueue_create_buffer[DType.int32](width * height)
        ctx.enqueue_function[mandelbrot_kernel](
            device,
            Int32(width),
            Int32(height),
            grid_dim=(ceildiv(width, 16), ceildiv(height, 16)),
            block_dim=(16, 16),
        )
        var gpu = ctx.enqueue_create_host_buffer[DType.int32](width * height)
        ctx.enqueue_copy(dst_buf=gpu, src_buf=device)
        ctx.synchronize()

        var cpu = mandelbrot_cpu(width, height)
        var differ = 0
        for i in range(width * height):
            if gpu[i] != cpu[i]:
                differ += 1
        print(
            "пикселей, где GPU и CPU разошлись:", differ, "из", width * height
        )
        # Совпадения бит в бит никто не обещает (см. главу), но расхождений
        # должно быть мало: доли процента пикселей, в основном у границы.
        assert_true(differ * 1000 < width * height, "слишком много расхождений")
    else:
        print("видеокарты нет — сравнение GPU и CPU пропущено")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
