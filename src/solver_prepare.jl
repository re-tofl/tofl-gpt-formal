using Symbolics

function make_smt_file(path, variables_array, simplified_left_parts)

    solver_text = ""

    add2solver = s -> solver_text *= s * "\n"

    for v ∈ variables_array
        add2solver("(declare-const $v Int)")
    end

    for v ∈ variables_array
        add2solver("(assert (>= $v 1))")
    end

    variable_symbols = Symbol.(collect(variables_array))
    @eval @variables $(variable_symbols...)

    add2solver("(assert (or")
    for left_part ∈ simplified_left_parts 
        expr = Meta.parse(left_part)
        add2solver("(<= $(infix_to_prefix(expr)) 0)")
    end
    add2solver("))")
    add2solver("(check-sat)")

    open(path, "w") do file
        write(file, solver_text)
    end
end


@enum SolverStatus begin
    Sat = 0
    Unsat = 1
    Unknown = 2
end

function get_status_and_variables(smt_file)
    output = open(`z3 -model $smt_file`, "r") do io
        read(io, String)
    end

    lines = map(strip, split(output, "\n"))
    if lines[1] ≠ "sat"
        return lines[1] == "unsat" ? 
            Unsat : 
            Unknown, 
            nothing
    end
    
    result = Dict()
    for (var_line, value_line) ∈ zip(
            lines[3:2:length(lines)-2], 
            lines[4:2:length(lines)-1]
        )
        var = split(var_line)[2]
        value = rstrip(value_line, ')')
        result[var] = value
    end
    
    Sat, result
end

function infix_to_prefix(expr)
    if expr isa Symbol
        return string(expr)
    elseif expr isa Number
        return string(expr)
    else
        operator, args... = expr.args
        prefix_args = map(infix_to_prefix, args)
        return "(" * string(operator) * " " * join(prefix_args, " ") * ")"
    end
end