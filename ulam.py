import sys
import psyco
psyco.full()

UP = 0
LEFT = 1
DOWN = 2
RIGHT = 3

DIRECTIONS = {UP: (0, -1),
              LEFT: (-1, 0),
              DOWN: (0, 1),
              RIGHT: (1, 0)}

def generate_ulam_seq(n):
    start = 41
    x = 0
    y = 0
    min_x = 0
    max_x = 0
    min_y = 0
    max_y = 0
    value = start
    direction = UP
    for i in xrange(n):
        yield x, y, value
        value += 1
        add_x, add_y = DIRECTIONS[direction]
        x, y = x + add_x, y + add_y
        if x <min_x:
            direction = (direction+1) % 4
            min_x = x
        if x> max_x:
            direction = (direction+1) % 4
            max_x = x
        if y <min_y:
            direction = (direction+1) % 4
            min_y = y
        if y> max_y:
            direction = (direction+1) % 4
            max_y = y

def is_prime(n):
    return all(n%x != 0 for x in xrange(2, int((n**0.5) + 1)))

def main():
    for x, y, v in generate_ulam_seq(int(sys.argv[1])):
        if x == y and not is_prime(v):
            print x, y, v

if __name__ == '__main__':
    main()
