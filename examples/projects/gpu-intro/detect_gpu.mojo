from std.sys import has_accelerator

from max.gpu.host import DeviceContext


def main() raises:
    comptime if has_accelerator():
        var ctx = DeviceContext()
        print("Видеокарта:", ctx.name())
        print("API:", ctx.api())
    else:
        print("Видеокарта не найдена, считать будем на процессоре")
