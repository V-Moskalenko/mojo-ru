from std.sys import has_accelerator

from max.gpu import block_dim, block_idx, thread_idx
from max.gpu.host import DeviceContext


def print_threads():
    var i = block_idx.x * block_dim.x + thread_idx.x
    print(block_idx.x, thread_idx.x, i, sep="\t")


def main() raises:
    comptime if has_accelerator():
        var ctx = DeviceContext()
        print("блок\tпоток\tномер")
        ctx.enqueue_function[print_threads](grid_dim=2, block_dim=4)
        ctx.synchronize()
        print("готово")
    else:
        print("Видеокарта не найдена: этому примеру нужен GPU")
