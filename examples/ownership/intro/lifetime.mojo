# Когда именно Mojo уничтожает значение.


@fieldwise_init
struct Resource:
    """Ресурс, который громко сообщает о своей жизни и смерти."""

    var name: String

    def use(self):
        """Отмечает очередное использование."""
        print("используем:", self.name)

    def __deinit__(deinit self):
        """Вызывается, когда значение больше не нужно."""
        print("уничтожен:", self.name)


def consume(var item: Resource):
    """Забирает владение ресурсом себе."""
    print("функция получила владение:", item.name)


def main():
    var first = Resource("первый")
    var second = Resource("второй")

    first.use()
    second.use()
    first.use()

    print("--- first больше не нужен ---")

    second.use()

    print("--- second больше не нужен ---")

    var third = Resource("третий")
    consume(third^)
    print("--- владение передано ---")
