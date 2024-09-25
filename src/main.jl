using JSON
using Symbolics
#include(joinpath(@__DIR__,"interpretation.jl"))
#include(joinpath(@__DIR__,"structures.jl"))
#include(joinpath(@__DIR__,"parsing_terms.jl"))
#include(joinpath(@__DIR__,"json_and_interpret_hardcode.jl"))
#include(joinpath(@__DIR__,"interpret_parse.jl"))

#########################stuctures
# Структура для термов
struct Term
    name::String
    childs::Vector{Term}
end
##########################json_

# Захардкоженная JSON строка с функциями f и g
json_interpret = """
{
  "functions": [
    {
      "name": "f",
      "variables": ["x, y, z"],
      "expression": "(x^2 + x + 2 * y + z)"
    },
    {
      "name": "g",
      "variables": ["y"],
      "expression": "(y + 1)"
    },
    {
      "name": "h",
      "variables": ["x"],
      "expression": "(x^3 + 1)"
    },
    {
      "name": "u",
      "variables": ["y"],
      "expression": "(y + 12)"
    }
  ]
}
"""

# Пример JSON, содержащий левую и правую часть TRS
json_string_first = """
[
    {
        "value": "f",
        "childs": [
            {
                "value": "f",
                "childs": [
                    {
                        "value": "x1",
                        "childs": []
                    },
                    {
                        "value": "x2",
                        "childs": []
                    },
                    {
                        "value": "x3",
                        "childs": []
                    }
                ]
            }
        ]
    },
    {
        "value": "h",
        "childs": [
            {
                "value": "y1",
                "childs": []
            }
        ]
    }
]
"""

json_string_second= """
[
    {
        "value": "g",
        "childs": [
            {
                "value": "u",
                "childs": [
                    {
                        "value": "x2",
                        "childs": []
                    }
                ]
            }
        ]
    },
    {
        "value": "h",
        "childs": [
            {
                "value": "y2",
                "childs": []
            }
        ]
    }
]
"""
##########################interpret_parse
# Функция для парсинга интерпретаций из JSON и подстановки переменных TRS
function parse_interpretations(interpretations::Dict{String, Function}, var_map::Dict{String, String})
    parsed_data = JSON.parse(json_interpret)

    for func in parsed_data["functions"]
        func_name = func["name"]
        variables = split(func["variables"][1], ", ")  # Разбиваем переменные по запятой
        expression = func["expression"]

        # Создаем функцию с нужным количеством переменных
        interpretations[func_name] = (vars...) -> begin
            expr = expression
            # Заменяем переменные в выражении на соответствующие переменные из TRS (var_map)
            for (i, var) in enumerate(variables)
                expr = replace(expr, var => get(var_map, vars[i], vars[i]))  # Используем переменные TRS
            end
            return expr
        end
    end
end

##########################################parsing_terms
# Функция для парсинга термов из JSON
function parse_term(json::Dict)
    childs = [parse_term(child) for child in json["childs"]]
    return Term(json["value"], childs)
end

# Объявляем переменные для библиотеки упрощения полиномов
@variables x1 y1 x2 y2

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


# Функция для парсинга и интерпретации TRS
function parse_and_interpret(json_string::String, interpretations::Dict{String, Function})
    parsed_json = JSON.parse(json_string)

    # Парсим левую и правую части TRS
    left_term = parse_term(parsed_json[1])
    right_term = parse_term(parsed_json[2])

    # Создаем словарь var_map, который сопоставляет переменные из TRS с переменными интерпретаций
    var_map = Dict{String, String}()

    # Собираем переменные из TRS и добавляем их в var_map
    function collect_vars(term::Term)
        for child in term.childs
            if !haskey(var_map, child.name)
                var_map[child.name] = child.name  # Добавляем переменную в var_map
            end
            collect_vars(child)  # Рекурсивно проходим по дочерним термам
        end
    end

    # Собираем переменные из левого и правого термов
    collect_vars(left_term)
    collect_vars(right_term)

    # Парсим интерпретации с переменными из TRS, передаем var_map
    parse_interpretations(interpretations, var_map)

    # Применяем интерпретацию к левой и правой части TRS
    interpreted_left = apply_interpretation(left_term, interpretations, var_map)
    interpreted_right = apply_interpretation(right_term, interpretations, var_map)

    # Выводим результат
    println("\nПодстановка интерпретации:")
    println("Левая часть: $interpreted_left")
    println("Правая часть: $interpreted_right")
end





############################interpretation
# Функция для применения интерпретаций
# Функция для применения интерпретаций
function apply_interpretation(term::Term, interpretations::Dict{String, Function}, var_map::Dict{String, String})
    if isempty(term.childs)
        # Если это переменная, возвращаем её значение из var_map, если оно существует, иначе имя переменной
        return get(var_map, term.name, term.name)
    else
        # Применяем интерпретацию для функции
        interpreted_childs = [apply_interpretation(child, interpretations, var_map) for child in term.childs]
        if haskey(interpretations, term.name)
            interp_func = interpretations[term.name]
            # Вызов функции интерпретации с подставленными дочерними термами
            return interp_func(interpreted_childs...)
        else
            return "$term.name(" * join(interpreted_childs, ", ") * ")"
        end
    end
end



# Функция для вывода интерпретации в человекочитаемом виде с переменными из TRS
function interpretation_to_string(interpretations::Dict, var_map::Dict{String, String})
    interp_strings = []
    for (func_name, func_interp) in pairs(interpretations)
        # Определяем количество аргументов для функции
        func_method = first(methods(func_interp))
        num_args = length(func_method.sig.parameters) - 1  # Количество аргументов у функции

        # Создаем список переменных на основе количества аргументов
        args = ["x$i" for i in 1:num_args]
        mapped_args = [get(var_map, arg, arg) for arg in args]  # Заменяем переменные из TRS

        # Передача переменных в функцию интерпретации по отдельности
        result = func_interp(mapped_args...)  # Передаем переменные как отдельные аргументы

        # Генерация строки результата
        args_str = join(mapped_args, ", ")
        push!(interp_strings, "$func_name($args_str) = $result")
    end
    return join(interp_strings, "\n")
end





###########################################

# Создаем пустой словарь для интерпретаций
# parse_interpretations(interpretations)
# println(interpretations)

# Создаем пустой словарь для интерпретаций
interpretations = Dict{String, Function}()
parse_and_interpret(json_string_first, interpretations)
parse_and_interpret(json_string_second, interpretations)

