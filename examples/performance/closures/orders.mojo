# Отбор и подсчёт заказов замыканиями.
# Каждый способ захвата здесь нужен по делу, а не для показа.


@fieldwise_init
struct Order(Copyable, Movable):
    var id: Int
    var amount: Int  # в рублях


def count_matching[P: def(Order) -> Bool, //](
    orders: List[Order], predicate: P
) -> Int:
    """Функция высшего порядка: условие приходит замыканием."""
    var found = 0
    for order in orders:
        if predicate(order):
            found += 1
    return found


def main():
    var orders = List[Order]()
    orders.append(Order(1, 500))
    orders.append(Order(2, 12000))
    orders.append(Order(3, 3000))
    orders.append(Order(4, 45000))

    # imm — читаем порог и видим его текущее значение
    var threshold = 1000

    def is_large(o: Order) {imm threshold} -> Bool:
        return o.amount > threshold

    print("крупнее", threshold, ":", count_matching(orders, is_large))

    threshold = 10000
    print("крупнее", threshold, ":", count_matching(orders, is_large))

    # mut — накапливаем сумму
    var total = 0

    def add(o: Order) {mut total}:
        total += o.amount

    for order in orders:
        add(order)
    print("всего:", total)

    # var — копия на момент объявления, снимок
    var limit = 5000

    def under_snapshot(o: Order) {var limit} -> Bool:
        return o.amount < limit

    limit = 1
    print("после limit = 1 замыкание всё ещё считает по 5000:")
    print("  подходит заказов:", count_matching(orders, under_snapshot))
    print("  а limit сейчас:", limit)

    # лямбда — для условия в одну строку список захвата не нужен
    print("дороже 40000:", count_matching(orders, lambda (o: Order) -> Bool: o.amount > 40000))
