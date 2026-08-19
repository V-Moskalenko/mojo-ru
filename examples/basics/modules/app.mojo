"""Точка входа: собирает пакет фигур и общий модуль вместе."""

import geometry
from geometry import to_centimeters
from shapes import Circle, Rectangle


def main():
    var circle = Circle(2.0)
    var rectangle = Rectangle(3.0, 4.0)

    print(circle, "площадь", circle.area())
    print(rectangle, "площадь", rectangle.area())

    print("PI из модуля:", geometry.PI)
    print("два метра в сантиметрах:", to_centimeters(2.0))
