# Копирование и перемещение: что бесплатно, а что стоит денег.


@fieldwise_init
struct Connection:
    """Соединение с базой. Копировать его нельзя — только передавать."""

    var name: String

    def query(self, sql: String):
        """Выполняет запрос."""
        print("  ", self.name, "->", sql)

    def __deinit__(deinit self):
        """Закрывает соединение, когда оно перестало быть нужным."""
        print("   закрыто:", self.name)


@fieldwise_init
struct Snapshot(Copyable):
    """Выгрузка данных. Копировать можно, но видно, что это не бесплатно."""

    var rows: List[Int]

    def copy(self) -> Self:
        """Создаёт копию и сообщает, сколько строк пришлось скопировать."""
        print("   копируем строк:", len(self.rows))
        return Snapshot(self.rows.copy())


def run(var connection: Connection, sql: String):
    """Забирает соединение себе — и закрывает его, когда закончит."""
    connection.query(sql)


def main():
    print("1. перемещение: объект тот же, копии нет")
    var primary = Connection("основное")
    var moved = primary^
    moved.query("SELECT 1")

    print("2. владение уходит в функцию — она же и закрывает")
    run(moved^, "SELECT 2")
    print("   вернулись из функции")

    print("3. копия — только по явной просьбе")
    var snapshot = Snapshot([1, 2, 3])
    var backup = snapshot.copy()
    print("   строк в оригинале и копии:", len(snapshot.rows), len(backup.rows))

    print("4. соединения кладём в список — тоже перемещением")
    var pool = List[Connection]()
    pool.append(Connection("первое"))
    pool.append(Connection("второе"))
    print("   в пуле:", len(pool))

    print("5. обмен значениями без единой копии")
    var left = String("раз")
    var right = String("два")
    swap(left, right)
    print("  ", left, right)
