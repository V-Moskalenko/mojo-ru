from std.math import ceildiv
from std.sys import has_accelerator

from max.gpu.host import DeviceContext

from fractal import mandelbrot_cpu, mandelbrot_kernel, render

comptime WIDTH = 72
comptime HEIGHT = 28
comptime BLOCK = 16


def main() raises:
    comptime if has_accelerator():
        var ctx = DeviceContext()
        var device = ctx.enqueue_create_buffer[DType.int32](WIDTH * HEIGHT)
        ctx.enqueue_function[mandelbrot_kernel](
            device,
            Int32(WIDTH),
            Int32(HEIGHT),
            grid_dim=(ceildiv(WIDTH, BLOCK), ceildiv(HEIGHT, BLOCK)),
            block_dim=(BLOCK, BLOCK),
        )
        var host = ctx.enqueue_create_host_buffer[DType.int32](WIDTH * HEIGHT)
        ctx.enqueue_copy(dst_buf=host, src_buf=device)
        ctx.synchronize()
        render(host.as_span(), WIDTH, HEIGHT)
    else:
        var iters = mandelbrot_cpu(WIDTH, HEIGHT)
        render(iters, WIDTH, HEIGHT)
