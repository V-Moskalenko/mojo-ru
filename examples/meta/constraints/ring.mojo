# Кольцевой буфер фиксированной ёмкости.
# Два требования к ёмкости записаны по-разному:
#   - «больше нуля» — where: условие попадает в сигнатуру типа;
#   - «степень двойки» — comptime assert ради понятного сообщения.
# Технически второе тоже выразилось бы через where (битовые операции
# решателю доступны), но тогда пользователь читал бы машинный текст.


struct Ring[capacity: Int](Copyable, Movable) where capacity > 0:
    var data: Array[Int, Self.capacity]
    var count: Int

    def __init__(out self):
        # Проверка при сборке: маска вместо деления работает только
        # для степеней двойки. Сообщение своё — его и прочитает тот,
        # кто ошибётся с ёмкостью.
        comptime assert (
            Self.capacity & (Self.capacity - 1)
        ) == 0, "ёмкость кольца должна быть степенью двойки"
        self.data = Array[Int, Self.capacity](fill=0)
        self.count = 0

    def copy(self) -> Self:
        var result = Self()
        comptime for i in range(Self.capacity):
            result.data[i] = self.data[i]
        result.count = self.count
        return result^

    def push(mut self, value: Int):
        # Быстрый остаток: работает благодаря той самой степени двойки.
        self.data[self.count & (Self.capacity - 1)] = value
        self.count += 1

    def get(self, index: Int) -> Int:
        return self.data[index & (Self.capacity - 1)]

    def title(self) -> String:
        # describe требует n > 0. Доказательство берётся из ограничения
        # самой структуры — своего where здесь писать не нужно.
        return describe[Self.capacity]()

    def window[start: Int, end: Int](
        self,
    ) -> Array[Int, end - start] where end > start and end <= Self.capacity:
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

    # Ни одна из этих строк не соберётся:
    #
    #   var zero = Ring[0]()        # violated constraint: (capacity > Int(0))
    #   var odd = Ring[6]()         # ёмкость кольца должна быть степенью двойки
    #   var bad = ring.window[5, 2]()   # violated constraint (составное, см. ниже)
    #
    # Компилятор печатает составное условие как вложенное:
    #   expected '(end <= capacity) if (end > start) else (end > start)'
    print("три ошибки поймались бы при сборке, а не при запуске")
