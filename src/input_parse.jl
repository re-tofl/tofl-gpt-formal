function read_input(prompt)
    input = ""
    result = ""
    
    println(prompt)
    while true
        line = readline()
        result *= line * "\n"

        if isempty(line)
            break
        end

    end

    return result
end

using JSON

# Функция для парсинга TRS строки
function parse_trs_string_demo(trs_string::String)
    rules = split(trs_string, '\n') |> filter(!isempty)
    trs_json = []

    for rule in rules
        left, right = split(rule, "->") |> x -> strip.(x)
        left_tree = parse_expression_demo(String(left))
        right_tree = parse_expression_demo(String(right))
        push!(trs_json, Dict("left" => left_tree, "right" => right_tree))
    end

    return JSON.json(trs_json)
end


# Рекурсивная функция для парсинга выражения
# Рекурсивная функция для парсинга выражения
function parse_expression_demo(expr::String)
    expr = strip(expr)
    # Если выражение имеет формат f(...) - рекурсивный случай
    if occursin('(', expr)
        func_name, args = match(r"(\w+)\((.*)\)", expr).captures
        args = split_args_demo(String(args))
        child_trees = [parse_expression_demo(String(arg)) for arg in args]
        return Dict("value" => func_name, "childs" => child_trees)
    else
        # Базовый случай - это просто переменная или константа
        return Dict("value" => expr, "childs" => [])
    end
end

# Функция для разбивки аргументов по запятым
function split_args_demo(args::String)
    depth = 0
    buffer = ""
    result = []

    for c in args
        if c == ',' && depth == 0
            push!(result, strip(buffer))
            buffer = ""
        else
            buffer *= c
            if c == '('
                depth += 1
            elseif c == ')'
                depth -= 1
            end
        end
    end

    if !isempty(buffer)
        push!(result, strip(buffer))
    end

    return result
end

# Функция для парсинга строки интерпретаций
function parse_interpret_string_demo(interpret_string::String)
    interpretations = split(interpret_string, '\n') |> filter(!isempty)
    functions = []

    for interpretation in interpretations
        left, right = split(interpretation, "=") |> x -> strip.(x)
        func_name, args = match(r"(\w+)\((.*)\)", left).captures
        variables = split(args, ",") |> x -> strip.(x)
        expression = "($right)"
        push!(functions, Dict("name" => func_name, "variables" => variables, "expression" => expression))
    end

    return JSON.json(Dict("functions" => functions))
end
