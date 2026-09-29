# ожидается: expected ':' after 'except'


def main():
    try:
        _ = Int("abc")
    except Error as e:
        print(e)
