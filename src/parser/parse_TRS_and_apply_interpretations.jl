module Parser

include("types.jl")

using Symbolics
using JSON

export parse_and_interpret, separatevars, MissingJSONField

struct MissingJSONField <: Exception
           filed
end

Base.showerror(io::IO, e::MissingJSONField) = print(io, "JSON поле $(e.field) не определено")

############################ Функция для применения интерпретаций
function apply_interpretation(term, interpretations, var_map)::String
    if isempty(term.childs)
        # Если это переменная, возвращаем ее имя
        return term.name
    else
        # Применяем интерпретацию для функции
        interpreted_childs = [apply_interpretation(child, interpretations, var_map) for child ∈ term.childs]
        if haskey(interpretations, term.name)
            interp_func = interpretations[term.name]
            # Вызываем функцию интерпретации с подставленными дочерними термами
            return interp_func(interpreted_childs...)
        else
            return "$(term.name)(" * join(interpreted_childs, ", ") * ")"
        end
    end
end

########################### Функция для переименования переменных в TRS
function renamevars!(jsonterm1, jsonterm2, renamefunc)
    rename! = function (j)
        if isempty(j["childs"])
            j["value"] = renamefunc(j["value"])
        else
            foreach(rename!, j["childs"])
        end
    end

    foreach(rename!, (jsonterm1, jsonterm2))
end

"""
Разделяет переменные в каждом выражении, добавляя
индекс. Возвращает json-строку 
"""
function separatevars(json_string)::String
    json_exprs = JSON.parse(json_string)
    for (index, expr) ∈ enumerate(json_exprs)
        renamevars!(expr["left"], expr["right"], x -> "$(x)_$index")
    end
    JSON.json(json_exprs)
end


"""
Возвращает вектор переменных и вектор полимномов, всё в виде строк
"""
function parse_and_interpret(json_string, json_interpretations)
    variables_array = Vector()
    simplified_left_parts = Vector()

    parsed_json = JSON.parse(json_string)

    # Проверяем, что parsed_json является массивом правил
    if !isa(parsed_json, Array)
        throw(ArgumentError("ожидаетя массив JSON правил"))
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
        left_term = make_term_from_json(rule["left"])
        right_term = make_term_from_json(rule["right"])

        # Создаём словарь var_map для сопоставления переменных из текущего правила
        var_map = Dict{String, String}()

        # Собираем переменные из текущего правила
        variable_names = Set{String}()
        function collect_vars(term::Term)
            if isempty(term.childs)
                # Если терм — переменная, добавляем его имя в var_map и variable_names
                var_map[term.name] = term.name
                push!(variable_names, term.name)
            else
                # Терм — функция, обрабатываем её дочерние элементы
                for child ∈ term.childs
                    collect_vars(child)
                end
            end
        end

        # Собираем переменные из левой и правой частей
        collect_vars(left_term)
        collect_vars(right_term)

        # Динамически объявляем переменные
        variable_symbols = Symbol.(collect(variable_names))
        @eval @variables $(variable_symbols...)

        append!(variables_array, string.(variable_symbols))

        interpretations = parse_interpretations(json_interpretations)

        # Применяем интерпретацию к левой и правой части текущего правила
        interpreted_left = apply_interpretation(left_term, interpretations, var_map)
        interpreted_right = apply_interpretation(right_term, interpretations, var_map)

        # Выводим правило TRSS
        left_term_str = term_to_string(left_term)
        right_term_str = term_to_string(right_term)
        println("\nПравило TRS:")
        println("$left_term_str -> $right_term_str")

        # Упрощение интерпретаций
        left_expr = interpreted_left |> Meta.parse |> eval |> Symbolics.simplify
        right_expr = interpreted_right |> Meta.parse |> eval |> Symbolics.simplify

        # Дополнительное упрощение с раскрытием скобок
        left_expr_expanded = Symbolics.expand(left_expr)
        right_expr_expanded = Symbolics.expand(right_expr)

        # Вычисляем разность и упрощаем
        difference = Symbolics.simplify(left_expr_expanded - right_expr_expanded)
        difference_expanded = Symbolics.expand(difference)

        println("\nВыражение:")
        println("$(left_expr_expanded) = $(right_expr_expanded)")
        println("После упрощения:")
        println("$(difference_expanded) = 0")

        # Сохраняем левую часть выражения
        push!(simplified_left_parts, string(difference_expanded))
    end

    variables_array, simplified_left_parts
end

########################## Функция для парсинга интерпретаций
function parse_interpretations(json_interpret_string)
    interpretations::Dict{String, Function} = Dict()

    parsed_data = JSON.parse(json_interpret_string)
    for func ∈ parsed_data["functions"]
        func_name = func["name"]
        variables = func["variables"]
        expression = func["expression"]

        # Создаем функцию с необходимым количеством переменных
        interpretations[func_name] = (vars...) -> begin
            expr = expression
            # Заменяем переменные в выражении на соответствующие переменные из TRS
            for (i, var) ∈ enumerate(variables)
                # Используем регулярные выражения для замены целых слов
                expr = replace(expr, Regex("\\b$(var)\\b") => vars[i])
            end
            return expr
        end
    end

    interpretations
end

########################################## Функция для парсинга термов
# Функция для парсинга термов из JSON
function make_term_from_json(json::Dict)
    childs = [make_term_from_json(child) for child ∈ json["childs"]]
    return Term(json["value"], childs)
end

# Функция для отображения терма в человекочитаемом виде
function term_to_string(term::Term)
    if isempty(term.childs)
        return term.name  # Если терм — переменная, возвращаем его имя
    else
        # Рекурсивно обрабатываем дочерние термы
        child_strings = [term_to_string(child) for child ∈ term.childs]
        return "$(term.name)(" * join(child_strings, ", ") * ")"
    end
end

end