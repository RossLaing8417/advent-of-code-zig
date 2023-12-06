# Advent of Code - Zig

Solving Advent of Code using Zig

## Executing

Edited build.zig to accept year, day, and part args:

```
zig build -Dyear=2023 -Dday=1 -Dpart=1
```

Note: `year` and `day` args are optional, they will default to todays year and day, `part` is mandatory (subject to change) and is either 1 or 2, e.g:

```
zig build -Dpart=2
```

## TODO

- [ ] Generate directories and files using a template
