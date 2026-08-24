# Прайс-лист. У книг и кофе общее ровно одно — у каждого есть цена.
# Этого хватает, чтобы написать подсчёт суммы один раз.


@fieldwise_init
struct Money(ImplicitlyCopyable, Comparable, Writable):
    """Деньги в копейках: во Float64 их хранить нельзя из-за округлений."""

    var kopeks: Int

    # Достаточно одного __lt__ — остальные пять операторов сравнения
    # трейт Comparable добавляет сам.
    def __lt__(self, other: Self) -> Bool:
        return self.kopeks < other.kopeks

    # write_to даёт и print(), и String(): отдельного трейта
    # для строкового представления в Mojo 1.0 нет.
    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.kopeks // 100, " ₽")


trait Priced:
    """Цена обязательна, наличие — нет: у него есть значение по умолчанию."""

    def price(self) -> Money:
        ...

    def in_stock(self) -> String:
        return String("под заказ")


@fieldwise_init
struct Book(Copyable, Priced):
    var title: String
    var kopeks: Int

    def price(self) -> Money:
        return Money(self.kopeks)

    def in_stock(self) -> String:
        return String("на складе")


@fieldwise_init
struct Coffee(Copyable, Priced):
    var grams: Int

    def price(self) -> Money:
        return Money(self.grams * 350)

    # in_stock не реализован — возьмётся значение по умолчанию.


def total[T: Priced & Movable](items: List[T]) -> Money:
    """Работает с любым списком товаров, лишь бы у них была цена.

    Второе требование, Movable, идёт от List, а не от задачи.
    """
    var subtotal = 0
    for item in items:
        subtotal += item.price().kopeks
    return Money(subtotal)


def show[T: Priced](item: T, name: String):
    print("  ", name, "—", item.price(), "|", item.in_stock())


def main():
    # Тип указан явно: голый литерал [...] дал бы Array, а не List.
    var books: List[Book] = [Book("Мойо", 89000), Book("Расты", 125050)]
    var coffee: List[Coffee] = [Coffee(250), Coffee(1000)]

    print("книги:")
    for b in books:
        show(b, b.title)
    print("итого:", total(books))

    print("кофе:")
    for c in coffee:
        show(c, String(c.grams) + String(" г"))
    print("итого:", total(coffee))

    # Списки приходится держать раздельно: List[Priced] не существует.
    # Сравнение при этом работает, хотя написан только __lt__.
    print("дороже ли кофе книг:", total(coffee) > total(books))
