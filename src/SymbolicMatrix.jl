using Values

struct SymbolicMatrix
    m::Value
    n::Value
    cases::Dict{Constraint,Function} # Constraint => (i::Value, j::Value) -> Value

    function SymbolicMatrix(m::Value, n::Value, cases::Dict{<:Constraint,<:Function})
        new(m, n, cases)
    end
    function SymbolicMatrix(m::Number, n::Number, cases::Dict{<:Constraint,<:Function})
        new(Value(m), Value(n), cases)
    end
end

function element_at(m::SymbolicMatrix, i::Int, j::Int)
    for (constraint, value_func) in m.cases
        if constraint(i, j)
            return value_func(i, j)
        end
    end
    return nothing
end

function show_range(io::IO, m::SymbolicMatrix, il::Int, ih::Int, jl::Int, jh::Int)
    for i in il:ih
        for j in jl:jh
            e = element_at(m, i, j)
            print(io, e)
            print(io, "\t")
        end
        println(io)
    end
end

function show_range(m::SymbolicMatrix, il::Int, ih::Int, jl::Int, jh::Int)
    show_range(stdout, m, il, ih, jl, jh)
end

function Base.:(+)(matrix1::SymbolicMatrix, matrix2::SymbolicMatrix)::SymbolicMatrix
    @assert matrix1.m == matrix2.m
    @assert matrix1.n == matrix2.n
    cases = Dict{Constraint,Function}()
    for (c1, v1) in matrix1.cases
        for (c2, v2) in matrix2.cases
            cases[simplify_and(AndConstraint((c1, c2)))] = (i, j) -> v1(i, j) + v2(i, j)
        end
    end
    return SymbolicMatrix(matrix1.m, matrix1.n, cases)
end

function Base.:(-)(matrix1::SymbolicMatrix, matrix2::SymbolicMatrix)::SymbolicMatrix
    @assert matrix1.m == matrix2.m
    @assert matrix1.n == matrix2.n
    cases = Dict{Constraint,Function}()
    for (c1, v1) in matrix1.cases
        for (c2, v2) in matrix2.cases
            cases[simplify_and(AndConstraint((c1, c2)))] = (i, j) -> v1(i, j) - v2(i, j)
        end
    end
    return SymbolicMatrix(matrix1.m, matrix1.n, cases)
end

function Base.:(*)(matrix1::SymbolicMatrix, scalar::Union{Number,Expr,Symbol,Value})::SymbolicMatrix
    cases = Dict{Constraint,Function}()
    for (c1, v1) in matrix1.cases
        cases[c1] = (i, j) -> v1(i, j) * scalar
    end
    return SymbolicMatrix(matrix1.m, matrix1.n, cases)
end

Base.:(*)(scalar::Union{Number,Expr,Symbol,Value}, matrix1::SymbolicMatrix)::SymbolicMatrix = matrix1 * scalar
Base.:-(matrix::SymbolicMatrix)::SymbolicMatrix = matrix * -1
Base.:+(matrix::SymbolicMatrix)::SymbolicMatrix = matrix

function Base.show(io::IO, matrix::SymbolicMatrix)
    println(io, "Symbolic Matrix ($(matrix.m) x $(matrix.n))")
    for (c1, v1) in matrix.cases
        println(io, "\t$(c1) -> $(v1(ConstraintValue.i,ConstraintValue.j))")
    end
end