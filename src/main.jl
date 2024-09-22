using JSON

# Интерпретации функций
interpretations = Dict(
    "f" => (x) -> "(($x)^2 + $x + 2)",  # f(x, y) = xy + y^2
    "g" => (y) -> "($y + 1)",               # g(y) = y + 1
    "h" => (x) -> "($x^3 + 13)",     # h(x, y) = x^2 + 2y
    "u" => (y) -> "($y + 12)"               # u(y) = y + 12
)

# Структура для термов
struct Term
    name::String
    childs::Vector{Term}
end

# Функция для парсинга термов из JSON
function parse_term(json)
    childs = [parse_term(child) for child in json["childs"]]
    return Term(json["value"], childs)
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

# Функция для применения интерпретаций
function apply_interpretation(term::Term, interpretations::Dict)
    if isempty(term.childs)
        return term.name  # Возвращаем имя переменной как строку
    else
        # Применяем интерпретацию к каждому дочернему терму
        interpreted_childs = [apply_interpretation(child, interpretations) for child in term.childs]

        # Передаем дочерние термы в интерпретацию
        return interpretations[term.name](interpreted_childs...)  # Вызов интерпретации с правильными аргументами
    end
end

# Функция для вывода интерпретации в человекочитаемом виде
function interpretation_to_string(interpretations::Dict)
    interp_strings = []
    for (func_name, func_interp) in pairs(interpretations)
        # Определяем количество аргументов у функции
        args = if func_name == "f" || func_name == "h"
            "x"
        else
            "y"
        end

        # Добавляем интерпретацию в виде строки, корректно передавая аргументы
        if func_name == "f" || func_name == "h"
            push!(interp_strings, "$func_name($args) = $(func_interp("x"))")
        else
            push!(interp_strings, "$func_name($args) = $(func_interp("y"))")
        end
    end
    return join(interp_strings, "\n")
end

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
                        "value": "f",
                        "childs": [
                            {
                                "value": "x1",
                                "childs": []
                            }
                        ]
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
        "value": "f",
        "childs": [
            {
                "value": "f",
                "childs": [
                    {
                        "value": "f",
                        "childs": [
                            {
                                "value": "x1",
                                "childs": []
                            }
                        ]
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
function parse_it!(json_string::String)
    parsed_json = JSON.parse(json_string)

    # Парсим левую и правую часть TRS
    left_term = parse_term(parsed_json[1])
    right_term = parse_term(parsed_json[2])

    # Преобразование термов в человекочитаемую строку (TRS)
    left_term_str = term_to_string(left_term)
    right_term_str = term_to_string(right_term)

    # Выводим правила TRS в человекочитаемом виде
    println("Правило TRS:")
    println("$left_term_str -> $right_term_str")

    # Выводим интерпретации в человекочитаемом виде
    println("\nИнтерпретации функций:")
    println(interpretation_to_string(interpretations))

    # Применение интерпретации к левой части
    left_polynomial = apply_interpretation(left_term, interpretations)
    println("\nЛевая часть после интерпретации: ", left_polynomial)

    # Применение интерпретации к правой части
    right_polynomial = apply_interpretation(right_term, interpretations)
    println("Правая часть после интерпретации: ", right_polynomial)
end

parse_it!(json_string_first)
