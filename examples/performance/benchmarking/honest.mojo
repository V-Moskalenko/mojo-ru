# Два замера одного и того же цикла. Первый врёт, второй — нет.
#
# Программа печатает не сами наносекунды (они у вас будут свои),
# а вердикт: правдоподобен результат или нет.

from std.benchmark import run, keep
from std.sys import argv

comptime N = 4096

# Порог правдоподобия, с большим запасом.
# Одна операция быстрее сотой доли такта не выполняется никогда: даже
# векторный код на широком процессоре доходит лишь до десятых долей.
# 0.003 нс — это примерно сотая такта на машине в 3 ГГц.
comptime IMPOSSIBLE_NS = 0.003


def verdict(name: String, ns_per_item: Float64):
    if ns_per_item < IMPOSSIBLE_NS:
        print(name, "— подозрительно: столько не бывает, цикл свёрнут")
    else:
        print(name, "— правдоподобно")


def main() raises:
    # Значение из argv известно только при запуске. Само по себе это
    # свёртку не предотвращает (проверено), но лишним не будет.
    var unknown = len(argv())

    # Главное — данные лежат в куче: содержимое динамической памяти
    # оптимизатор через границу замера не протаскивает.
    var data = List[Int](capacity=N)
    for i in range(N):
        data.append((i * 2654435761) % 1000 + unknown)

    # ЛОВУШКА: и границы цикла, и все слагаемые известны при сборке.
    # keep() не спасает — он мешает выбросить результат, но не мешает
    # посчитать его заранее.
    @parameter
    def folded():
        var total = 0
        for i in range(N):
            total += i * i
        keep(total)

    # ЧЕСТНО: числа читаются из кучи. Вот это свернуть не выйдет.
    @parameter
    def honest():
        var total = 0
        for i in range(len(data)):
            total += data[i]
        keep(total)

    # .min(), а не .mean(): шум только добавляет время, никогда не убавляет.
    var folded_ns = run[folded](max_runtime_secs=0.3).min() * 1e9
    var honest_ns = run[honest](max_runtime_secs=0.3).min() * 1e9

    verdict(String("константы   "), folded_ns / Float64(N))
    verdict(String("данные      "), honest_ns / Float64(N))

    print()
    print("вывод: мерить нужно то, что лежит в памяти, а не в исходнике")
