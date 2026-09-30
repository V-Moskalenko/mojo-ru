# Паузы и замер времени. Печатаем только то, что не зависит от машины.
from std.time import perf_counter, perf_counter_ns, sleep


def main():
    var start = perf_counter_ns()
    sleep(0.05)  # секунды, можно дробные
    var elapsed = perf_counter_ns() - start
    print("прошло не меньше 50 мс:", elapsed >= 50_000_000)

    var t0 = perf_counter()
    sleep(0.01)
    var seconds = perf_counter() - t0
    print("в секундах, Float64:", seconds >= 0.01)
