# SymbolicMatrices.jl

A Julia module for defining symbolic matrices with constraints and performing basic matrix operations.


## Usage

### Defining Constraints

The following constraints are supported:
- `LessThan(left, right)` — Defines a constraint where `left < right`.
- `GreaterThan(left, right)` — Defines a constraint where `left > right`.
- `Equal(left, right)` — Defines a constraint where `left == right`.
- `NotEqual(left, right)` — Defines a constraint where `left != right`.
- `AddConstraint((constraints))` — Defines a compound constraint where all of the constraints must be satisfied.
- `OrConstraint((constraints))` — Defines a compound constraint where any of the constraints must be satisfied.

Each constraint is defined using [`Value`](https://github.com/alcyon-lab/Values.jl) type. To use matrix indices in constraints, use `ConstraintValue.i` and `ConstraintValue.j`.

### Creating a Symbolic Matrix

To create a symbolic matrix, define its dimensions (`m`, `n`) and a dictionary of constraints with corresponding value functions. Each value function returns the value for a matrix element if the constraint is satisfied.

```julia
matrix = SymbolicMatrix(
        Value(:m), Value(:n), 
        Dict(
            LessThan(ConstraintValue.i, ConstraintValue.j) => ((i, j) -> Value(:q)),
            Equal(ConstraintValue.i, ConstraintValue.j) => ((i, j) -> 1),
            GreaterThan(ConstraintValue.i, ConstraintValue.j) => ((i, j) -> 2)
        )
    )
# returns
# Symbolic Matrix (:m x :n)
#    :i == :j -> 1
#    :i > :j -> 2
#    :i < :j -> :q
```

### Accessing Elements

```julia
element = element_at(matrix, 2, 3) 
# :q
```

### Displaying Matrix Within a Specified Range

```julia
show_range(m, 1, 3, 1, 3)
# 1       :q      :q
# 2       1       :q
# 2       2       1
```

### Matrix Operations

The module supports basic matrix operations like addition, subtraction and mulitpliying by a scalar.

```julia
matrix1 = SymbolicMatrix(
        Value(:m), Value(:n), 
        Dict(
            LessThan(ConstraintValue.i, ConstraintValue.j) => ((i, j) -> Value(:q)),
            Equal(ConstraintValue.i, ConstraintValue.j) => ((i, j) -> 1),
            GreaterThan(ConstraintValue.i, ConstraintValue.j) => ((i, j) -> 2)
        )
)
matrix2 = SymbolicMatrix(
        Value(:m), Value(:n), 
        Dict(
            Equal(ConstraintValue.j, 2) => ((i, j) -> 5),
            NotEqual(ConstraintValue.j, 2) => ((i, j) -> 0),
        )
)

show_range(matrix1, 1,3,1,3)
# 1         :q        :q
# 2         1         :q
# 2         2         1 
show_range(matrix2, 1,3,1,3)
# 0         5         0 
# 0         5         0 
# 0         5         0 

# addition
matrix3 = matrix1 + matrix2
show_range(matrix3, 1,3,1,3)
# 1         :(q + 5)  :(q + 0)
# 2         6         :(q + 0)
# 2         7         1       

# subtraction
matrix4 = matrix1 - matrix2
show_range(matrix4, 1,3,1,3)
# 1         :(q - 5)  :(q - 0)
# 2         -4        :(q - 0)
# 2         -3        1       

# multiplication by a scalar
matrix5 = matrix1 * 10
show_range(matrix5, 1,3,1,3)
# 10        :(q * 10) :(q * 10)
# 20        10        :(q * 10)
# 20        20        10       

```
