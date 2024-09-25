using Symbolics
############################ Функция для применения интерпретаций
function apply_interpretation(term::Term, interpretations::Dict{String, Function}, var_map::Dict{String, String})
    if isempty(term.childs)
        # Если это переменная, возвращаем ее имя
        return term.name
    else
        # Применяем интерпретацию для функции
        interpreted_childs = [apply_interpretation(child, interpretations, var_map) for child in term.childs]
        if haskey(interpretations, term.name)
            interp_func = interpretations[term.name]
            # Вызываем функцию интерпретации с подставленными дочерними термами
            return interp_func(interpreted_childs...)
        else
            return "$(term.name)(" * join(interpreted_childs, ", ") * ")"
        end
    end
end

########################## Функция для парсинга и интерпретации TRS
function parse_and_interpret(json_string::String, interpretations::Dict{String, Function})
    parsed_json = JSON.parse(json_string)

    # Парсим левую и правую части TRS
    left_term = parse_term(parsed_json[1])
    right_term = parse_term(parsed_json[2])

    # Создаем словарь var_map, который сопоставляет переменные из TRS переменным интерпретаций
    var_map = Dict{String, String}()

    # Собираем переменные из TRS и добавляем их в var_map
    variable_names = Set{String}()
    function collect_vars(term::Term)
        if isempty(term.childs)
            # Если терм — переменная, добавляем его имя в var_map и variable_names
            var_map[term.name] = term.name
            push!(variable_names, term.name)
        else
            # Терм — функция, обрабатываем ее дочерние элементы
            for child in term.childs
                collect_vars(child)
            end
        end
    end

    # Собираем переменные из левой и правой частей
    collect_vars(left_term)
    collect_vars(right_term)

    # Динамически объявляем переменные
    # Преобразуем имена переменных в символы
    variable_symbols = Symbol.(collect(variable_names))
    # Объявляем переменные с помощью @variables и @eval
    @eval @variables $(variable_symbols...)

    # Парсим интерпретации с переменными из TRS, передаем var_map
    parse_interpretations(interpretations, var_map)

    # Применяем интерпретацию к левой и правой части TRS
    interpreted_left = apply_interpretation(left_term, interpretations, var_map)
    interpreted_right = apply_interpretation(right_term, interpretations, var_map)

    # Выводим правило TRS
    left_term_str = term_to_string(left_term)
    right_term_str = term_to_string(right_term)
    println("\nПравило TRS:")
    println("$left_term_str -> $right_term_str")

    # Упрощение интерпретаций
    left_expr = Symbolics.simplify(eval(Meta.parse(interpreted_left)))
    right_expr = Symbolics.simplify(eval(Meta.parse(interpreted_right)))

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
end