include(joinpath(@__DIR__,"structures.jl"))
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