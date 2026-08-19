# Структуры на практике: товар, корзина и трейты.


@fieldwise_init
struct Product(ImplicitlyCopyable, Writable):
    """Товар: название, цена в рублях и количество."""

    var name: String
    var price: Int
    var quantity: Int

    @staticmethod
    def single(name: String, price: Int) -> Product:
        """Создаёт товар в единственном экземпляре."""
        return Product(name, price, 1)

    def total(self) -> Int:
        """Считает стоимость позиции целиком."""
        return self.price * self.quantity

    def __eq__(self, other: Self) -> Bool:
        """Товары считаются одинаковыми, если совпало название."""
        return self.name == other.name

    def write_to[W: Writer](self, mut writer: W):
        """Печатает позицию так, как её увидит покупатель."""
        writer.write(self.name, " x", self.quantity, " = ", self.total(), " руб.")


struct Cart(Writable):
    """Корзина: товары плюс правила доставки."""

    comptime FREE_DELIVERY_FROM = 3000
    comptime DELIVERY_PRICE = 300

    var items: List[Product]

    def __init__(out self):
        """Создаёт пустую корзину."""
        self.items = List[Product]()

    def add(mut self, item: Product):
        """Добавляет позицию в корзину."""
        self.items.append(item)

    def subtotal(self) -> Int:
        """Считает стоимость товаров без доставки."""
        var sum = 0
        for item in self.items:
            sum += item.total()
        return sum

    def delivery(self) -> Int:
        """Возвращает стоимость доставки с учётом порога бесплатной."""
        return 0 if self.subtotal() >= Self.FREE_DELIVERY_FROM else Self.DELIVERY_PRICE

    def write_to[W: Writer](self, mut writer: W):
        """Печатает чек целиком."""
        for item in self.items:
            writer.write(item, "\n")
        writer.write("товаров на ", self.subtotal(), " руб.\n")
        writer.write("доставка: ", self.delivery(), " руб.\n")
        writer.write("итого: ", self.subtotal() + self.delivery(), " руб.")


def main():
    var cart = Cart()
    cart.add(Product("Клавиатура", 2500, 1))
    cart.add(Product("Мышь", 900, 2))
    cart.add(Product.single("Коврик", 400))

    print(cart)
    print()
    print("порог бесплатной доставки:", Cart.FREE_DELIVERY_FROM)
    print("первая позиция — клавиатура:", cart.items[0] == Product("Клавиатура", 1, 1))

    var small = Cart()
    small.add(Product.single("Кабель", 350))
    print()
    print(small)
