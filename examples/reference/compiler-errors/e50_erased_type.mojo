# ожидается: 'Error' value has no attribute 'reason'


@fieldwise_init
struct AgeError(Copyable, Writable):
    var reason: String

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.reason)


def check(age: Int) raises AgeError -> Int:
    raise AgeError("отрицательный")


def check_all(age: Int) raises -> Int:
    return check(age)


def main():
    try:
        _ = check_all(1)
    except e:
        print(e.reason)
