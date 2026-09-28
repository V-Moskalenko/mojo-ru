from std.math import ceildiv
from std.sys import has_accelerator

from max.gpu import block_dim, block_idx, thread_idx
from max.gpu.host import DeviceContext

comptime SIZE = 10
comptime BLOCK = 4


def add_scalar(
    data: Pointer[Float32, MutAnyOrigin], size: Int32, value: Float32
):
    var i = block_idx.x * block_dim.x + thread_idx.x
    if i < Int(size):
        data[unsafe_offset=i] += value


def main() raises:
    comptime if has_accelerator():
        var ctx = DeviceContext()

        # 1. Готовим данные в обычной памяти
        var host = ctx.enqueue_create_host_buffer[DType.float32](SIZE)
        ctx.synchronize()
        for i in range(SIZE):
            host[i] = Float32(i)
        print("было: ", host)

        # 2. Выделяем память на видеокарте и копируем туда данные
        var device = ctx.enqueue_create_buffer[DType.float32](SIZE)
        ctx.enqueue_copy(dst_buf=device, src_buf=host)

        # 3. Запускаем ядро: по потоку на элемент
        ctx.enqueue_function[add_scalar](
            device,
            Int32(SIZE),
            Float32(100),
            grid_dim=ceildiv(SIZE, BLOCK),
            block_dim=BLOCK,
        )

        # 4. Копируем результат обратно и ждём, пока всё выполнится
        ctx.enqueue_copy(dst_buf=host, src_buf=device)
        ctx.synchronize()
        print("стало:", host)
    else:
        print("Видеокарта не найдена: этому примеру нужен GPU")
