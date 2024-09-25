include(joinpath(@__DIR__,"structures.jl"))

# Функция для применения интерпретаций
function apply_interpretation(term::Term, interpretations::Dict{String, Function})
    if isempty(term.childs)
        return term.value  # Если это переменная, просто возвращаем её имя
    else
        # Применяем интерпретацию для функции
        interpreted_childs = [apply_interpretation(child, interpretations) for child in term.childs]
        if haskey(interpretations, term.value)
            interp_func = interpretations[term.value]
            return interp_func(interpreted_childs...)
        else
            return "$term.value(" * join(interpreted_childs, ", ") * ")"
        end
    end
end



# Функция для вывода интерпретации в человекочитаемом виде
function interpretation_to_string(interpretations::Dict)
    interp_strings = []
    for (func_name, func_interp) in pairs(interpretations)
        # Определяем список аргументов функции на основе количества аргументов
        func_method = first(methods(func_interp))
        num_args = length(func_method.sig.parameters) - 1  # -1 для исключения типа `Any`

        # Генерируем список аргументов в зависимости от их количества
        args = ["x$i" for i in 1:num_args]
        args_str = join(args, ", ")

        # Для каждого аргумента подставляем его имя в выражение
        eval_args = args  # используем список аргументов как аргументы вызова функции
        result = func_interp(eval_args...)  # вызываем функцию с аргументами

        # Добавляем интерпретацию в виде строки
        push!(interp_strings, "$func_name($args_str) = $result")
    end
    return join(interp_strings, "\n")
end

