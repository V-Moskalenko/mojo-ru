"""Прямоугольник."""


@fieldwise_init
struct Rectangle(ImplicitlyCopyable, Writable):
    """Прямоугольник, заданный сторонами."""

    var width: Float64
    var height: Float64

    def area(self) -> Float64:
        """Возвращает площадь прямоугольника."""
        return self.width * self.height

    def write_to[W: Writer](self, mut writer: W):
        """Печатает прямоугольник человекочитаемо."""
        writer.write("прямоугольник ", self.width, "x", self.height)
