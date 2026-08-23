# Что Mojo разрешает и запрещает — там, где Rust и C++ ведут себя иначе.


@fieldwise_init
struct Noisy:
    """Сообщает о своём уничтожении, чтобы был виден момент."""

    var name: String

    def __deinit__(deinit self):
        print("   уничтожен:", self.name)


@fieldwise_init
struct View[o: Origin]:
    """Структура, хранящая ссылку. Прямой аналог Rust-структуры с 'a."""

    var target: Pointer[Int, Self.o]

    def show(self):
        """Читает значение по ссылке."""
        print("   через ссылку:", self.target[])


def main():
    print("1. значение умирает сразу после последнего использования")
    var first = Noisy("первый")
    print("   используем:", first.name)
    print("   а эта строка печатается уже после уничтожения")

    print("2. две изменяемые ссылки на разные элементы — можно")
    var scores: List[Int] = [1, 2, 3]
    var low = Pointer(to=scores[0])
    var high = Pointer(to=scores[1])
    low[] = 10
    high[] = 20
    print("  ", scores[0], scores[1], scores[2])

    print("3. структура, которая хранит ссылку")
    var value = 42
    var view = View(Pointer(to=value))
    view.show()
