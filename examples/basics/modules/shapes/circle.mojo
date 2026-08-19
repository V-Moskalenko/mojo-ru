"""Круг."""

from geometry import PI


@fieldwise_init
struct Circle(ImplicitlyCopyable, Writable):
    """Круг, заданный радиусом."""

    var radius: Float64

    def area(self) -> Float64:
        """Возвращает площадь круга."""
        return PI * self.radius * self.radius

    def write_to[W: Writer](self, mut writer: W):
        """Печатает круг человекочитаемо."""
        writer.write("круг r=", self.radius)
