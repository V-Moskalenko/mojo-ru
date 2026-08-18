def average(values: List[Float64]) -> Float64:
    var total = 0.0
    for value in values:
        total += value
    return total / Float64(len(values))


def main():
    var measurements: List[Float64] = [21.5, 23.0, 19.8, 24.2]
    var mean = average(measurements)
    print("Средняя температура:", mean)
