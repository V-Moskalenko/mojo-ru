# ожидается: value has no attribute 'z'


@fieldwise_init
struct Point:
    var x: Int


def main():
    var p = Point(1)
    p.z = 5
