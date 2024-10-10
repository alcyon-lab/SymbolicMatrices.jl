using Values
abstract type Constraint end

const ConstraintValue = NamedTuple{(:i, :j)}((:i, :j))

struct LessThan <: Constraint
    left::Value
    right::Value
end
Base.:(==)(c1::LessThan, c2::LessThan) = c1.left == c2.left && c1.right == c2.right
Base.show(io::IO, c::LessThan) = print(io, "$(c.left) < $(c.right)")

struct GreaterThan <: Constraint
    left::Value
    right::Value
end
Base.:(==)(c1::GreaterThan, c2::GreaterThan) = c1.left == c2.left && c1.right == c2.right
Base.show(io::IO, c::GreaterThan) = print(io, "$(c.left) > $(c.right)")

struct Equal <: Constraint
    left::Value
    right::Value
end
Base.:(==)(c1::Equal, c2::Equal) = c1.left == c2.left && c1.right == c2.right
Base.show(io::IO, c::Equal) = print(io, "$(c.left) == $(c.right)")

struct NotEqual <: Constraint
    left::Value
    right::Value
end
Base.:(==)(c1::NotEqual, c2::NotEqual) = c1.left == c2.left && c1.right == c2.right
Base.show(io::IO, c::NotEqual) = print(io, "$(c.left) != $(c.right)")

struct AndConstraint <: Constraint
    constraints::Tuple{Vararg{Constraint}}

    function AndConstraint(constraints::Tuple{Vararg{Constraint}})
        if any(map(c -> c isa AndConstraint, constraints))
            flattened = Constraint[]
            for c in constraints
                if c isa AndConstraint
                    append!(flattened, c.constraints)
                else
                    push!(flattened, c)
                end
            end
            new(Tuple(flattened))
        else
            new(constraints)
        end
    end
end
Base.show(io::IO, c::AndConstraint) = print(io, join(c.constraints, " && "))

struct OrConstraint <: Constraint
    constraints::Tuple{Vararg{Constraint}}

    function OrConstraint(constraints::Tuple{Vararg{Constraint}})
        if any(map(c -> c isa OrConstraint, constraints))
            flattened = Constraint[]
            for c in constraints
                if c isa OrConstraint
                    append!(flattened, c.constraints)
                else
                    push!(flattened, c)
                end
            end
            new(Tuple(flattened))
        else
            new(constraints)
        end
    end
end
Base.show(io::IO, c::OrConstraint) = print(io, join(c.constraints, " || "))

# simplify (TODO: update those)
function simplify_and_pair(c1::LessThan, c2::LessThan)
    if c1.left == c2.left
        if isempty(Values.symbols(c1.right.val)) && isempty(Values.symbols(c2.right.val))
            return c1.right < c2.right ? c1 : c2
        end
    end
    if c1.right == c2.right
        if isempty(Values.symbols(c1.left.val)) && isempty(Values.symbols(c2.left.val))
            return c1.left < c2.left ? c2 : c1
        end
    end
    return AndConstraint((c1, c2))
end

function simplify_and_pair(c1::GreaterThan, c2::GreaterThan)
    if c1.left == c2.left
        if isempty(Values.symbols(c1.right.val)) && isempty(Values.symbols(c2.right.val))
            return c1.right < c2.right ? c2 : c1
        end
    end
    if c1.right == c2.right
        if isempty(Values.symbols(c1.left.val)) && isempty(Values.symbols(c2.left.val))
            return c1.left < c2.left ? c1 : c2
        end
    end
    return AndConstraint((c1, c2))
end

function simplify_and_pair(c1::LessThan, c2::GreaterThan)
    if c1.left == c2.right
        if isempty(Values.symbols(c1.right.val)) && isempty(Values.symbols(c2.left.val))
            return c1.right < c2.left ? c1 : c2
        end
    end
    if c1.right == c2.left
        if isempty(Values.symbols(c1.left.val)) && isempty(Values.symbols(c2.right.val))
            return c1.left < c2.right ? c2 : c1
        end
    end
    return AndConstraint((c1, c2))
end

function simplify_and_pair(c1::GreaterThan, c2::LessThan)
    return simplify_and_pair(c2, c1)
end

function simplify_and_pair(c1::Equal, c2::Equal)
    return (c1.left == c2.left && c1.right == c2.right) ? c1 : AndConstraint((c1, c2))
end

function simplify_and_pair(c1::NotEqual, c2::NotEqual)
    return (c1.left == c2.left && c1.right == c2.right) ? c1 : AndConstraint((c1, c2))
end

function simplify_and_pair(c1::AndConstraint, c2::AndConstraint)
    return AndConstraint((c1.constraints..., c2.constraints...))
end

function simplify_and_pair(c1::AndConstraint, c2::Constraint)
    return AndConstraint((c1.constraints..., c2))
end

function simplify_and_pair(c1::Constraint, c2::AndConstraint)
    return AndConstraint((c1, c2.constraints...))
end

function simplify_and_pair(c1::Constraint, c2::Constraint)
    return AndConstraint((c1, c2))
end

function simplify_and(constraints::Tuple{Vararg{Constraint}})
    simplified_constraints = []
    for c in constraints
        redundant = false
        for (i, existing) in enumerate(simplified_constraints)
            new_constraint = simplify_and_pair(c, existing)
            if new_constraint != AndConstraint((c, existing))
                simplified_constraints[i] = new_constraint
                redundant = true
                break
            end
        end
        if !redundant
            push!(simplified_constraints, c)
        end
    end
    return length(simplified_constraints) == 1 ? simplified_constraints[1] : AndConstraint(Tuple(simplified_constraints))
end

function simplify_and(constraint::AndConstraint)
    return simplify_and(constraint.constraints)
end

function simplify_or_pair(c1::LessThan, c2::LessThan)
    if c1.left == c2.left
        if isempty(Values.symbols(c1.right.val)) && isempty(Values.symbols(c2.right.val))
            return c1.right < c2.right ? c2 : c1
        end
    end
    if c1.right == c2.right
        if isempty(Values.symbols(c1.left.val)) && isempty(Values.symbols(c2.left.val))
            return c1.left < c2.left ? c1 : c2
        end
    end
    return OrConstraint((c1, c2))
end

function simplify_or_pair(c1::GreaterThan, c2::GreaterThan)
    if c1.left == c2.left
        if isempty(Values.symbols(c1.right.val)) && isempty(Values.symbols(c2.right.val))
            return c1.right < c2.right ? c1 : c2
        end
    end
    if c1.right == c2.right
        if isempty(Values.symbols(c1.left.val)) && isempty(Values.symbols(c2.left.val))
            return c1.left < c2.left ? c2 : c1
        end
    end
    return OrConstraint((c1, c2))
end

function simplify_or_pair(c1::LessThan, c2::GreaterThan)
    if c1.left == c2.right
        if isempty(Values.symbols(c1.right.val)) && isempty(Values.symbols(c2.left.val))
            return c1.right < c2.left ? c2 : c1
        end
    end
    if c1.right == c2.left
        if isempty(Values.symbols(c1.left.val)) && isempty(Values.symbols(c2.right.val))
            return c1.left < c2.right ? c1 : c2
        end
    end
    return OrConstraint((c1, c2))
end

function simplify_or_pair(c1::GreaterThan, c2::LessThan)
    return simplify_or_pair(c2, c1)
end

function simplify_or_pair(c1::Equal, c2::Equal)
    return (c1.left == c2.left && c1.right == c2.right) ? c1 : OrConstraint((c1, c2))
end

function simplify_or_pair(c1::NotEqual, c2::NotEqual)
    return (c1.left == c2.left && c1.right == c2.right) ? c1 : OrConstraint((c1, c2))
end

function simplify_or_pair(c1::OrConstraint, c2::OrConstraint)
    return OrConstraint((c1.constraints..., c2.constraints...))
end

function simplify_or_pair(c1::OrConstraint, c2::Constraint)
    return OrConstraint((c1.constraints..., c2))
end

function simplify_or_pair(c1::Constraint, c2::OrConstraint)
    return OrConstraint((c1, c2.constraints...))
end

function simplify_or_pair(c1::Constraint, c2::Constraint)
    return OrConstraint((c1, c2))
end

function simplify_or(constraints::Tuple{Vararg{Constraint}})
    simplified_constraints = []
    for c in constraints
        redundant = false
        for (i, existing) in enumerate(simplified_constraints)
            new_constraint = simplify_or_pair(c, existing)
            if new_constraint != OrConstraint((c, existing))
                simplified_constraints[i] = new_constraint
                redundant = true
                break
            end
        end
        if !redundant
            push!(simplified_constraints, c)
        end
    end
    return length(simplified_constraints) == 1 ? simplified_constraints[1] : OrConstraint(Tuple(simplified_constraints))
end

function simplify_or(constraint::OrConstraint)
    return simplify_or(constraint.constraints)
end

# evaluation

function (c::LessThan)(i_val::Int, j_val::Int)
    values = Dict(ConstraintValue.i => i_val, ConstraintValue.j => j_val)
    return eval(substitute(c.left, values)) < eval(substitute(c.right, values))
end

function (c::GreaterThan)(i_val::Int, j_val::Int)
    values = Dict(ConstraintValue.i => i_val, ConstraintValue.j => j_val)
    return eval(substitute(c.left, values)) > eval(substitute(c.right, values))
end

function (c::Equal)(i_val::Int, j_val::Int)
    values = Dict(ConstraintValue.i => i_val, ConstraintValue.j => j_val)
    return eval(substitute(c.left, values)) == eval(substitute(c.right, values))
end

function (c::NotEqual)(i_val::Int, j_val::Int)
    values = Dict(ConstraintValue.i => i_val, ConstraintValue.j => j_val)
    return eval(substitute(c.left, values)) != eval(substitute(c.right, values))
end

function (c::AndConstraint)(i_val::Int, j_val::Int)
    return all(map(e -> e(i_val, j_val), c.constraints))
end

function (c::OrConstraint)(i_val::Int, j_val::Int)
    return any(map(e -> e(i_val, j_val), c.constraints))
end
