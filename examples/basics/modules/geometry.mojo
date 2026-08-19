"""Общие константы и функции, не привязанные к конкретной фигуре."""

comptime PI = 3.14159


def to_centimeters(meters: Float64) -> Float64:
    """Переводит метры в сантиметры."""
    return meters * 100.0
