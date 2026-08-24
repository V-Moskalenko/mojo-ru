# Вектор фиксированной длины. Длина — параметр: она известна компилятору,
# поэтому он проверяет её сам и не даёт сложить несовместимое.


struct Vec[n: Int](Copyable, Movable):
    var data: Array[Float64, Self.n]

    def __init__(out self, fill: Float64 = 0.0):
        self.data = Array[Float64, Self.n](fill=fill)

    def copy(self) -> Self:
        """Нужен из-за Copyable: Array не копируется неявно."""
        var result = Self()
        comptime for i in range(Self.n):
            result.data[i] = self.data[i]
        return result^

    def __getitem__(self, index: Int) -> Float64:
        return self.data[index]

    def __setitem__(mut self, index: Int, value: Float64):
        self.data[index] = value

    def dot(self, other: Self) -> Float64:
        """Скалярное произведение. Цикл разворачивается при сборке."""
        var total = 0.0
        comptime for i in range(Self.n):
            total += self.data[i] * other.data[i]
        return total

    def concat[m: Int](self, other: Vec[m]) -> Vec[Self.n + m]:
        """Длина результата посчитана компилятором: Self.n + m."""
        var result = Vec[Self.n + m]()
        comptime for i in range(Self.n):
            result.data[i] = self.data[i]
        comptime for j in range(m):
            result.data[Self.n + j] = other.data[j]
        return result^


def length_squared[n: Int](v: Vec[n]) -> Float64:
    """Параметр n выводится из аргумента — писать его при вызове не нужно."""
    return v.dot(v)


def main():
    var a = Vec[3]()
    a[0] = 1.0
    a[1] = 2.0
    a[2] = 2.0

    print("длина известна типу:", a.n)
    print("квадрат длины:", length_squared(a))

    var ones = Vec[3](fill=1.0)
    print("скалярное произведение:", a.dot(ones))

    var copied = a.copy()
    copied[0] = 100.0
    print("копия независима:", a[0], "и", copied[0])

    # Длина результата вычислена при сборке: 3 + 2 = 5.
    var short = Vec[2](fill=5.0)
    var joined = a.concat(short)
    print("склейка длиной", joined.n, ":", joined[0], joined[3], joined[4])

    # А вот ради чего всё затевалось. Раскомментируйте — и программа
    # не соберётся, потому что Vec[3] и Vec[2] это разные типы:
    #
    #     print(a.dot(short))
    #
    # error: invalid call to 'dot': value passed to 'other' cannot be
    # converted from 'Vec[Int(2)]' to 'Vec[Int(3)]'
    print("несовпадение длин поймано бы при сборке, а не при запуске")
