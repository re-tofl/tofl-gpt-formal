using JSON
include(joinpath(@__DIR__,"json_and_interpret_hardcode.jl"))

function parse_interpretations(interpretations::Dict{String, Function})
    parsed_data = JSON.parse(json_interpret)

    for func in parsed_data["functions"]
        func_name = func["name"]
        variables = func["variables"]
        expression = func["expression"]

        # Сохраняем функцию в виде строки с переменными
        interpretations[func_name] = function(vars...)
            # Создаем подстановку для переменных
            expr = expression
            for (i, var) in enumerate(variables)
                expr = replace(expr, var => vars[i])
            end
            return expr
        end
    end
end


