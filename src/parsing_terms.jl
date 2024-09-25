using Symbolics
include(joinpath(@__DIR__,"structures.jl"))
#include(joinpath(@__DIR__,"main.jl"))

# Функция для парсинга термов из JSON
function parse_term(json::Dict)
    childs = [parse_term(child) for child in json["childs"]]
    return Term(json["value"], childs)
end

# Объявляем переменные для библиотеки упрощения полиномов
@variables x1 y1 x2 y2

# function parse_and_interpret(json_string::String)
#     parsed_json = JSON.parse(json_string)
#
#     # Парсим левую и правую часть TRS
#     left_term = parse_term(parsed_json[1])
#     right_term = parse_term(parsed_json[2])
#
#     # Преобразование термов в человекочитаемую строку (TRS)
#     left_term_str = term_to_string(left_term)
#     right_term_str = term_to_string(right_term)
#
#     # Выводим правила TRS в человекочитаемом виде
#     println("Правило TRS:")
#     println("$left_term_str -> $right_term_str")
#
#     # Выводим интерпретации в человекочитаемом виде
#     println("\nИнтерпретации функций:")
#     println(interpretation_to_string(interpretations))
#
#     # Применение интерпретации к левой и правой части
#     left_polynomial = apply_interpretation(left_term, interpretations)
#     right_polynomial = apply_interpretation(right_term, interpretations)
#
#     println("\nПодстановка интерпретации: ", Symbolics.simplify(eval(Meta.parse(left_polynomial))),
#     " = ", Symbolics.simplify(eval(Meta.parse(right_polynomial))))
# end

function parse_and_interpret(json_string::String, interpretations::Dict{String, Function})
    parsed_json = JSON.parse(json_string)

    # Если JSON — это массив, используйте индексы
    left_term = parse_term(parsed_json[1])  # Например, левый элемент
    right_term = parse_term(parsed_json[2])  # Правый элемент

    var_names = parsed_json["variables"]  # Если это отдельное поле, убедитесь, что оно существует
    var_map = Dict{String, String}()
    for (i, var) in enumerate(var_names)
        var_map[var] = "x$i"
    end

    interpreted_left = apply_interpretation(left_term, interpretations, var_map)
    interpreted_right = apply_interpretation(right_term, interpretations, var_map)

    println("Left Term with Interpretation: $interpreted_left")
    println("Right Term with Interpretation: $interpreted_right")
end



# Функция для отображения терма в человекочитаемом виде
function term_to_string(term::Term)
    if isempty(term.childs)
        return term.name  # Если терм — переменная, возвращаем её имя
    else
        # Рекурсивно обрабатываем дочерние термы
        child_strings = [term_to_string(child) for child in term.childs]
        return "$(term.name)(" * join(child_strings, ", ") * ")"  # Собираем строку в формате f(x, g(y))
    end
end