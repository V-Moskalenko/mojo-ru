# Модуль расширения для Python: одна горячая функция, переписанная на Mojo.
#
# Собирается и запускается со стороны Python — см. run_hotspot.py рядом.
# Отдельно эту программу запустить нельзя: точки входа main у неё нет,
# вместо неё PyInit_hotspot.

from std.python import PythonObject, Python
from std.python.bindings import PythonModuleBuilder
from std.os import abort
from std.math import sqrt


@export
def PyInit_hotspot() abi("C") -> PythonObject:
    """Точка входа. Имя обязано быть PyInit_<имя модуля>."""
    try:
        var m = PythonModuleBuilder("hotspot")
        m.def_function[sum_roots](
            "sum_roots", docstring="Сумма корней от 0 до n"
        )
        m.def_function[squares]("squares", docstring="Список квадратов")
        return m.finalize()
    except e:
        abort(String("не удалось создать модуль: ", e))


def sum_roots(py_n: PythonObject) raises -> PythonObject:
    """Горячий цикл: ради него всё и затевалось."""
    var n = Int(py=py_n)
    var total = 0.0
    for i in range(n):
        total += sqrt(Float64(i))
    return PythonObject(total)


def squares(py_n: PythonObject) raises -> PythonObject:
    """Возвращать можно и составные объекты Python."""
    var out = Python.list()
    for i in range(Int(py=py_n)):
        out.append(i * i)
    return out
