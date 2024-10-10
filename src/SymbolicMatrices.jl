module SymbolicMatrices

include("Constraint.jl")
include("SymbolicMatrix.jl")

export
    # Types
    SymbolicMatrix,
    Constraint,
    ConstraintValue,
    LessThan,
    GreaterThan,
    Equal,
    NotEqual,
    AndConstraint,
    OrConstraint,
    # Methods
    simplify_and,
    simplify_or,
    element_at,
    show_between
end
