# Где Mojo копирует значение, а где обходится без копии.


@fieldwise_init
struct Tracked(Copyable):
    """Значение, которое сообщает о каждом своём копировании."""

    var name: String
    var value: Int

    def copy(self) -> Self:
        """Создаёт копию и громко об этом сообщает."""
        print("   >>> копируем", self.name)
        return Tracked(self.name, self.value)

    def show(self):
        """Печатает имя и текущее значение."""
        print("  ", self.name, "=", self.value)


def look(item: Tracked):
    """Только читает аргумент."""
    item.show()


def take(var item: Tracked):
    """Забирает владение аргументом."""
    item.show()


def make(name: String) -> Tracked:
    """Создаёт значение и возвращает его наружу."""
    return Tracked(name, 100)


def main():
    var original = Tracked("оригинал", 1)

    print("1. читаем аргумент — копии нет:")
    look(original)

    print("2. возвращаем из функции — копии нет:")
    var made = make("созданный")
    made.show()

    print("3. копируем явно — копия одна:")
    var duplicate = original.copy()
    duplicate.name = "копия"
    duplicate.value = 2
    original.show()
    duplicate.show()

    print("4. передаём владение — копии нет:")
    take(original^)

    print("5. копия всегда глубокая:")
    var first: List[String] = ["раз", "два"]
    var second = first.copy()
    second[0] = "изменено"
    print("  ", first[0], "|", second[0])
