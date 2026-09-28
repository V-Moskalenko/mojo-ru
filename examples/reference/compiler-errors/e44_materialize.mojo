# ожидается: cannot materialize comptime value of type 'Array[Int, Int(4)]' to runtime because it is not 'ImplicitlyCopyable'

comptime TABLE = Array[Int, 4](fill=1)


def main():
    var t = TABLE
    t[0] = 5
    print(t[0])
