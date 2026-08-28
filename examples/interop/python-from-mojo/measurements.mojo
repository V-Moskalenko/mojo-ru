# Разделение труда: разбор — Python, счёт — Mojo.
#
# JSON парсить руками на Mojo незачем: в Python это одна строка.
# А вот считать по разобранным числам лучше уже своими средствами —
# каждый переход границы стоит сотни наносекунд.

from std.python import Python
from std.math import sqrt


def main() raises:
    var json = Python.import_module("json")

    var raw = String(
        '{"sensor": "t-42", "readings": [21.5, 23.0, 19.8, 24.2, 22.1]}'
    )

    # Граница пересекается один раз: разбираем всё сразу.
    var parsed = json.loads(raw)
    var name = String(py=parsed["sensor"])
    var py_readings = parsed["readings"]

    # Переносим числа в родной список — дальше Python не участвует.
    var readings = List[Float64]()
    for item in py_readings:
        readings.append(Float64(py=item))

    print("датчик:", name)
    print("замеров:", len(readings))

    # Всё остальное считается на Mojo.
    var total = 0.0
    var lowest = readings[0]
    var highest = readings[0]
    for value in readings:
        total += value
        if value < lowest:
            lowest = value
        if value > highest:
            highest = value

    var mean = total / Float64(len(readings))

    var variance = 0.0
    for value in readings:
        var d = value - mean
        variance += d * d
    variance /= Float64(len(readings))

    print("минимум:", lowest)
    print("максимум:", highest)
    print("среднее:", mean)
    print("отклонение:", sqrt(variance))
