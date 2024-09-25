using JSON
########################## Функция для парсинга интерпретаций
function parse_interpretations(interpretations::Dict{String, Function}, var_map::Dict{String, String})
    parsed_data = JSON.parse(json_interpret)

    for func in parsed_data["functions"]
        func_name = func["name"]
        variables = func["variables"]
        expression = func["expression"]

        # Создаем функцию с необходимым количеством переменных
        interpretations[func_name] = (vars...) -> begin
            expr = expression
            # Заменяем переменные в выражении на соответствующие переменные из TRS
            for (i, var) in enumerate(variables)
                # Используем регулярные выражения для замены целых слов
                expr = replace(expr, Regex("\\b$(var)\\b") => vars[i])
            end
            return expr
        end
    end
end

########################################## Функция для парсинга термов
# Функция для парсинга термов из JSON
function parse_term(json::Dict)
    childs = [parse_term(child) for child in json["childs"]]
    return Term(json["value"], childs)
end

# Функция для отображения терма в человекочитаемом виде
function term_to_string(term::Term)
    if isempty(term.childs)
        return term.name  # Если терм — переменная, возвращаем его имя
    else
        # Рекурсивно обрабатываем дочерние термы
        child_strings = [term_to_string(child) for child in term.childs]
        return "$(term.name)(" * join(child_strings, ", ") * ")"
    end
end