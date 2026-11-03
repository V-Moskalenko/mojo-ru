"""Замер: процессор (один поток и все ядра) против видеокарты.

Запуск: mojo build bench_mandelbrot.mojo && ./bench_mandelbrot 1920 1080
Вывод у каждой машины свой.
"""

from std.benchmark import keep
from std.math import ceildiv
from std.sys import argv, has_accelerator
from std.time import perf_counter_ns

from max.algorithm import parallelize
from max.gpu.host import DeviceContext

from fractal import (
    escape_time,
    mandelbrot_cpu,
    mandelbrot_kernel,
    pixel_to_point,
)


def mandelbrot_threads(width: Int, height: Int) -> List[Int32]:
    """Строки картинки делятся между ядрами процессора."""
    var iters = List[Int32](length=width * height, fill=0)
    var p = iters.unsafe_ptr()

    def one_row(row: Int) {imm p, imm width, imm height}:
        for col in range(width):
            var cx, cy = pixel_to_point(col, row, width, height)
            p[unsafe_offset=row * width + col] = escape_time(cx, cy)

    parallelize(one_row, height)
    return iters^


def report(name: String, seconds: Float64, pixels: Int):
    print(
        name,
        "  ",
        round(seconds * 1000, 2),
        "мс  ",
        round(Float64(pixels) / seconds / 1e6, 1),
        "Мпикс/с",
    )


def main() raises:
    var width = Int(argv()[1]) if len(argv()) > 1 else 1920
    var height = Int(argv()[2]) if len(argv()) > 2 else 1080
    var pixels = width * height
    print("картинка", width, "×", height)

    var best = Float64.MAX
    for _ in range(3):
        var t0 = perf_counter_ns()
        var iters = mandelbrot_cpu(width, height)
        best = min(best, Float64(perf_counter_ns() - t0) / 1e9)
        keep(iters[pixels - 1])
    report("CPU, один поток   ", best, pixels)

    best = Float64.MAX
    for _ in range(3):
        var t0 = perf_counter_ns()
        var iters = mandelbrot_threads(width, height)
        best = min(best, Float64(perf_counter_ns() - t0) / 1e9)
        keep(iters[pixels - 1])
    report("CPU, все ядра     ", best, pixels)

    comptime if has_accelerator():
        var ctx = DeviceContext()
        var device = ctx.enqueue_create_buffer[DType.int32](pixels)
        var host = ctx.enqueue_create_host_buffer[DType.int32](pixels)
        var grid = (ceildiv(width, 16), ceildiv(height, 16))
        ctx.synchronize()  # буферы созданы, дальше меряем только ядро

        # Первый запуск: сюда входят разовые расходы на загрузку ядра
        var t0 = perf_counter_ns()
        ctx.enqueue_function[mandelbrot_kernel](
            device,
            Int32(width),
            Int32(height),
            grid_dim=grid,
            block_dim=(16, 16),
        )
        ctx.synchronize()
        report(
            "GPU, первый запуск", Float64(perf_counter_ns() - t0) / 1e9, pixels
        )

        # Запуск ядра и ожидание, без копирования
        best = Float64.MAX
        for _ in range(5):
            t0 = perf_counter_ns()
            ctx.enqueue_function[mandelbrot_kernel](
                device,
                Int32(width),
                Int32(height),
                grid_dim=grid,
                block_dim=(16, 16),
            )
            ctx.synchronize()
            best = min(best, Float64(perf_counter_ns() - t0) / 1e9)
        report("GPU, только ядро  ", best, pixels)

        # Вычисления плюс копирование результата в обычную память
        best = Float64.MAX
        for _ in range(5):
            t0 = perf_counter_ns()
            ctx.enqueue_function[mandelbrot_kernel](
                device,
                Int32(width),
                Int32(height),
                grid_dim=grid,
                block_dim=(16, 16),
            )
            ctx.enqueue_copy(dst_buf=host, src_buf=device)
            ctx.synchronize()
            best = min(best, Float64(perf_counter_ns() - t0) / 1e9)
        keep(host[pixels - 1])
        report("GPU, ядро и копия ", best, pixels)
    else:
        print("видеокарты нет — замер GPU пропущен")
