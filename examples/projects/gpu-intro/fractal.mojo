"""Множество Мандельброта: общий код для процессора и видеокарты."""

from max.gpu import global_idx

comptime MAX_ITER = 200
"""Сколько шагов ждём, прежде чем решить, что точка не убегает."""


def escape_time(cx: Float32, cy: Float32) -> Int32:
    """Номер шага, на котором точка c = cx + i·cy убежала за радиус 2.

    Если за MAX_ITER шагов не убежала — считаем, что она в множестве,
    и возвращаем MAX_ITER.
    """
    var x: Float32 = 0
    var y: Float32 = 0
    for i in range(MAX_ITER):
        var x2 = x * x
        var y2 = y * y
        if x2 + y2 > 4:
            return Int32(i)
        y = 2 * x * y + cy
        x = x2 - y2 + cx
    return MAX_ITER


def pixel_to_point(
    col: Int, row: Int, width: Int, height: Int
) -> Tuple[Float32, Float32]:
    """Центр пикселя как точка прямоугольника [-2.2, 0.8] × [-1.2, 1.2]."""
    var step_x = Float32(3.0) / Float32(width)
    var step_y = Float32(2.4) / Float32(height)
    var cx = Float32(-2.2) + (Float32(col) + 0.5) * step_x
    var cy = Float32(-1.2) + (Float32(row) + 0.5) * step_y
    return (cx, cy)


def mandelbrot_kernel(
    iters: Pointer[Int32, MutAnyOrigin], width: Int32, height: Int32
):
    """Ядро: каждый поток видеокарты считает свой пиксель."""
    var col = global_idx.x
    var row = global_idx.y
    if col >= Int(width) or row >= Int(height):
        return
    var cx, cy = pixel_to_point(col, row, Int(width), Int(height))
    iters[unsafe_offset=row * Int(width) + col] = escape_time(cx, cy)


def mandelbrot_cpu(width: Int, height: Int) -> List[Int32]:
    """Та же картинка на процессоре — пиксель за пикселем."""
    var iters = List[Int32](length=width * height, fill=0)
    for row in range(height):
        for col in range(width):
            var cx, cy = pixel_to_point(col, row, width, height)
            iters[row * width + col] = escape_time(cx, cy)
    return iters^


def render(iters: Span[Int32, _], width: Int, height: Int):
    """Печатает картинку символами: чем дольше точка не убегает, тем гуще."""
    comptime shades = " .:-=+*#%"
    for row in range(height):
        var line = String()
        for col in range(width):
            var n = Int(iters[row * width + col])
            if n == MAX_ITER:
                line += "@"
            else:
                line += shades[byte=min(n // 2, shades.byte_length() - 1)]
        print(line)
