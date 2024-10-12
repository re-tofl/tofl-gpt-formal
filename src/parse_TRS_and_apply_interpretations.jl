include("types.jl")
include("reply_func.jl")

using Symbolics
using JSON

struct MissingJSONField <: Exception
           field
end

Base.showerror(io::IO, e::MissingJSONField) = print(io, "JSON поле $(e.field) не определено")

### Функция для применения интерпретаций
function apply_interpretation(term, interpretations)::String
    if haskey(interpretations, term.name)
        interpreted_childs = [apply_interpretation(child, interpretations) for child ∈ term.childs]
        interp_func = interpretations[term.name]
        # Вызываем функцию интерпретации с подставленными дочерними термами
        return interp_func(interpreted_childs...)
    elseif term.is_variable
        # Это переменная
        return term.name
    else
        # Реконструируем терм без интерпретации
        interpreted_childs = [apply_interpretation(child, interpretations) for child ∈ term.childs]
        return isempty(interpreted_childs) ? term.name : "$(term.name)(" * join(interpreted_childs, ", ") * ")"
    end
end


### Функция для переименования переменных в TRS
function renamevars!(term1, term2, renamefunc)
    rename! = function (t)
        if t.is_variable
            t.name = renamefunc(t.name)
        end
        foreach(rename!, t.childs)
    end
    foreach(rename!, (term1, term2))
end


### Разделяет переменные в каждом выражении, добавляя индекс
function separatevars!(term_pairs)
    for (index, pair) ∈ enumerate(term_pairs)
        renamevars!(pair[1], pair[2], x -> "$(x)_$index")
    end
end

function collect_vars(term)
    result = Set()
    inner_collect_vars = (term) -> begin
        if isempty(term.childs) && term.is_variable
            push!(result, term.name)
        else
            foreach(inner_collect_vars, term.childs)
        end
    end
    inner_collect_vars(term)
    result
end

### Возвращает вектор переменных и вектор полиномов, всё в виде строк
function get_term_pairs_from_JSON(json_TRS_string, function_symbols)
    parsed_json = JSON.parse(json_TRS_string)
    term_pairs = Vector()
    if !isa(parsed_json, Array)
        throw(ArgumentError("ожидается массив JSON правил"))
    end
    for rule ∈ parsed_json
        if !haskey(rule, "left")
            throw(MissingJSONField("left"))
        end
        if !haskey(rule, "right")
            throw(MissingJSONField("right"))
        end
        left_term = make_term_from_json(rule["left"], function_symbols)
        right_term = make_term_from_json(rule["right"], function_symbols)
        push!(term_pairs, (left_term, right_term))
    end
    term_pairs
end


function parse_and_interpret(term_pairs, interpretations)
    variables_array = Vector()
    simplified_left_parts = Vector()
    for term_pair ∈ term_pairs
        left_term = term_pair[1]
        right_term = term_pair[2]

        # Собираем переменные из текущего правила
        variable_names = collect_vars(left_term) ∪ collect_vars(right_term)

        # Динамически объявляем переменные, если они есть
        variable_symbols = Symbol.(collect(variable_names))
        if !isempty(variable_symbols)
            @eval @variables $(variable_symbols...)
            append!(variables_array, string.(variable_symbols))
        end

        # Применяем интерпретацию к левой и правой части текущего правила
        interpreted_left = apply_interpretation(left_term, interpretations)
        interpreted_right = apply_interpretation(right_term, interpretations)

        # Выводим правило TRS
        left_term_str = term_to_string(left_term)
        right_term_str = term_to_string(right_term)

        println("\nПравило TRS:")

        code_reply("$left_term_str -> $right_term_str")

        println("$left_term_str -> $right_term_str")

        # Упрощение интерпретаций
        left_expr_expanded, right_expr_expanded = (interpreted_left, interpreted_right) .|>
            Meta.parse .|>
            eval .|>
            Symbolics.simplify .|>
            Symbolics.expand

        # Вычисляем разность и упрощаем
        difference = Symbolics.simplify(left_expr_expanded - right_expr_expanded)
        difference_expanded = Symbolics.expand(difference)

        println("\nПосле подстановки интерпретаций и упрощения:")
        println("$(difference_expanded) -> 0")

        # Сохраняем левую часть выражения
        push!(simplified_left_parts, string(difference_expanded))
    end

    variables_array, simplified_left_parts
end


function parse_interpretations(json_interpret_string)
    interpretations::Dict{String, Function} = Dict()

    parsed_data = JSON.parse(json_interpret_string)
    for func ∈ parsed_data["functions"]
        func_name = func["name"]
        variables = func["variables"]
        expression = func["expression"]

        interpretations[func_name] = (vars...) -> begin
            expr = expression
            # Проверяем, есть ли переменные для замены
            if !isempty(variables)
                # Заменяем переменные в выражении на соответствующие значения из vars
                for (i, var) ∈ enumerate(variables)
                    expr = replace(expr, Regex("\\b$(var)\\b") => vars[i])
                end
            end
            return expr
        end
    end

    interpretations
end

function make_term_from_json(json::Dict, function_symbols)
    childs = [make_term_from_json(child, function_symbols) for child ∈ json["childs"]]

    if function_symbols ≡ nothing
        # Если интерпретации не предоставлены
        is_variable = isempty(childs)
    else
        # Определяем is_variable на основе function_symbols и наличия дочерних термов
        if length(childs) > 0 || in(json["value"], function_symbols)
            is_variable = false  # Это функция
        else
            is_variable = true   # Это переменная
        end
    end
    return Term(json["value"], childs, is_variable)
end

### Возвращает вектор строк правил TRS
function json_trs_to_string(json_string)
    all_rules_in_string = Vector()

    parsed_json = JSON.parse(json_string)

    # Проверяем, что parsed_json является массивом правил
    if !isa(parsed_json, Array)
        throw(ArgumentError("ожидаетcя массив JSON правил"))
    end

    # Проходим по каждому правилу в массиве
    for rule ∈ parsed_json
        # Проверяем, что правило содержит ключи "left" и "right"
        if !haskey(rule, "left")
            throw(MissingJSONField("left"))
        end
        if !haskey(rule, "right")
            throw(MissingJSONField("right"))
        end
        # Парсим левую и правую части правила
        left_term = make_term_from_json(rule["left"], nothing)  # Передаём nothing, т.к. это для лабы
        right_term = make_term_from_json(rule["right"], nothing)

        # Выводим правило TRS
        left_term_str = term_to_string(left_term)
        right_term_str = term_to_string(right_term)
        rule_in_string = "$left_term_str -> $right_term_str"
        push!(all_rules_in_string, rule_in_string)
    end

    return all_rules_in_string
end
