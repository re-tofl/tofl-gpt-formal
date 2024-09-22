using Symbolics
include(joinpath(@__DIR__,"structures.jl"))

# Функция для парсинга термов из JSON
function parse_term(json)
    childs = [parse_term(child) for child in json["childs"]]
    return Term(json["value"], childs)
end

# Объявляем переменные для библиотеки упрощения полиномов
@variables x1 y1 x2 y2

function parse_and_interpret(json_string::String)
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

    # Применение интерпретации к левой и правой части
    left_polynomial = apply_interpretation(left_term, interpretations)
    right_polynomial = apply_interpretation(right_term, interpretations)

    println("\nПодстановка интерпретации: ", Symbolics.simplify(eval(Meta.parse(left_polynomial))),
    " = ", Symbolics.simplify(eval(Meta.parse(right_polynomial))))
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