# Три вида указателей и одна задача, которую в Mojo 1.0 приходится
# решать обходным путём.

from std.memory import Pointer, OwnedPointer, ArcPointer, Layout, dealloc


@fieldwise_init
struct Config(Movable, Deinitable):
    """Настройки, которые читают из нескольких мест."""

    var retries: Int


@fieldwise_init
struct Buffer(Movable, Deinitable):
    """Буфер, у которого владелец ровно один."""

    var size: Int


# Односвязный список в Mojo 1.0 через указатели не построить:
# структура не может ссылаться на себя. Ссылки заменяем индексами.
@fieldwise_init
struct Item(Copyable, Movable):
    var value: Int
    var next: Int  # -1 — конец списка


def main():
    print("1. Pointer — ссылка на уже существующее значение")
    var counter = 10
    var view = Pointer(to=counter)
    counter += 5
    print("   значение через указатель:", view[])

    print("2. OwnedPointer — владелец ровно один")
    var buffer = OwnedPointer(Buffer(4096))
    print("   размер буфера:", buffer[].size)
    # var copy = buffer — не соберётся: копировать владельца нельзя

    print("3. ArcPointer — владельцев несколько, есть счётчик")
    var config = ArcPointer(Config(3))
    print("   ссылок:", config.count())
    var shared = config
    print("   после копии:", config.count())
    print("   попыток из обеих копий:", config[].retries, shared[].retries)

    print("4. Сырая память: выделили — обязаны освободить")
    var block = alloc(Layout[Int](count=3))
    var raw = block.unsafe_ptr()
    for i in range(3):
        raw.unsafe_store(i, i * 100)
    print("   содержимое:", raw.unsafe_load(0), raw.unsafe_load(2))
    dealloc(block^)

    print("5. Список без указателей: ссылки — индексы массива")
    var items = List[Item]()
    items.append(Item(1, 1))
    items.append(Item(2, 2))
    items.append(Item(3, -1))
    print("   обход:", end="")
    var i = 0
    while i >= 0:
        print(" ", items[i].value, end="")
        i = items[i].next
    print()
