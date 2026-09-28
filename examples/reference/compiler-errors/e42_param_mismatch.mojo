# ожидается: cannot be converted from 'Vec[Int(2)]' to 'Vec[Int(3)]'


struct Vec[n: Int](Copyable):
    def __init__(out self):
        pass

    def dot(self, other: Self) -> Int:
        return Self.n


def main():
    print(Vec[3]().dot(Vec[2]()))
