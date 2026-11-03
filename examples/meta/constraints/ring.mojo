# Кольцевой буфер фиксированной ёмкости.
# Оба требования к ёмкости записаны в сигнатуре типа, у каждого своё
# сообщение после else — его и прочитает тот, кто ошибётся с ёмкостью.


struct Ring[capacity: Int](Copyable, Movable) where (
    capacity > 0
) else "ёмкость кольца должна быть положительной" where (
    (capacity & (capacity - 1)) == 0
) else "ёмкость кольца должна быть степенью двойки":
    var data: Array[Int, Self.capacity]
    var count: Int

    def __init__(out self):
        self.data = Array[Int, Self.capacity](fill=0)
        self.count = 0

    def copy(self) -> Self:
        var result = Self()
        comptime for i in range(Self.capacity):
            result.data[i] = self.data[i]
        result.count = self.count
        return result^

    def push(mut self, value: Int):
        # Быстрый остаток вместо деления: работает только благодаря
        # степени двойки, которую гарантирует второе условие.
        self.data[self.count & (Self.capacity - 1)] = value
        self.count += 1

    def get(self, index: Int) -> Int:
        return self.data[index & (Self.capacity - 1)]

    def title(self) -> String:
        # describe требует n > 0. Доказательство берётся из ограничения
        # самой структуры — своего where здесь писать не нужно.
        return describe[Self.capacity]()

    def window[
        start: Int, end: Int
    ](self) -> Array[Int, end - start] where (
        end > start
    ) else "окно не может быть пустым" where (
        end <= Self.capacity
    ) else "окно выходит за пределы кольца":
        """Кусок буфера. Оба условия проверяются при сборке."""
        var result = Array[Int, end - start](fill=0)
        comptime for i in range(end - start):
            result[i] = self.data[start + i]
        return result^


def describe[n: Int]() -> String where n > 0:
    """Требует положительного n — и не умеет это доказывать само."""
    return String("кольцо на ") + String(n)


def main():
    var ring = Ring[8]()
    for value in range(12):
        ring.push(value)

    print(ring.title())
    print("последнее записанное:", ring.get(11))
    print("всего записей:", ring.count)

    var part = ring.window[2, 5]()
    print("окно [2, 5):", part[0], part[1], part[2])

    # Ни одна из этих строк не соберётся — и каждая скажет, почему:
    #
    #   var zero = Ring[0]()            # ёмкость кольца должна быть положительной
    #   var odd = Ring[6]()             # ёмкость кольца должна быть степенью двойки
    #   var bad = ring.window[5, 2]()   # окно не может быть пустым
    print("три ошибки поймались бы при сборке, а не при запуске")
