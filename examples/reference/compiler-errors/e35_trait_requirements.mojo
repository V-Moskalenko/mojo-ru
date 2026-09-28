# ожидается: does not implement all requirements for 'Shape'


trait Shape:
    def area(self) -> Float64:
        ...


struct Square(Shape):
    var side: Float64


def main():
    pass
