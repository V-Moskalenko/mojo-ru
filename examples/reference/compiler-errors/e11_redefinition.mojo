# ожидается: redefinition of function 'show' with identical signature


def show(x: Int):
    print(x)


def show(y: Int):
    print(y)


def main():
    show(1)
