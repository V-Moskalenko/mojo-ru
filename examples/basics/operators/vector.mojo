@fieldwise_init
struct Vec2(ImplicitlyCopyable):
    """Двумерный вектор с перегруженными операторами."""

    var x: Float64
    var y: Float64

    def __add__(self, other: Vec2) -> Vec2:
        return Vec2(self.x + other.x, self.y + other.y)

    def __sub__(self, other: Vec2) -> Vec2:
        return Vec2(self.x - other.x, self.y - other.y)

    def __mul__(self, factor: Float64) -> Vec2:
        return Vec2(self.x * factor, self.y * factor)

    def __eq__(self, other: Vec2) -> Bool:
        return self.x == other.x and self.y == other.y

    def show(self, label: String):
        print(label, "(" + String(self.x) + ", " + String(self.y) + ")")


def main():
    var a = Vec2(1.0, 2.0)
    var b = Vec2(3.0, 4.0)

    (a + b).show("сумма:")
    (b - a).show("разность:")
    (a * 3.0).show("умножение на число:")
    print("равны ли a и a:", a == Vec2(1.0, 2.0))

    # Обычная арифметика и приоритет операций — как в Python
    print("2 + 3 * 4 =", 2 + 3 * 4)
    print("(2 + 3) * 4 =", (2 + 3) * 4)
    print("2 в степени 10:", 2**10)
    print("остаток 7 % 3:", 7 % 3)

    # Побитовые операции
    print("5 & 3 =", 5 & 3, "  5 | 3 =", 5 | 3, "  5 ^ 3 =", 5 ^ 3)
    print("сдвиги:", 1 << 4, 16 >> 2)

    # Сравнения можно объединять в цепочку
    var age = 25
    print("18 <= age < 65:", 18 <= age < 65)
