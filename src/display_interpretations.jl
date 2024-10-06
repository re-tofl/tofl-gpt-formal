using JSON

function display_interpretations()
    parsed_data = JSON.parse(json_interpret_string)
    println("\nИсходные интерпретации:")
    for func ∈ parsed_data["functions"]
        func_name = func["name"]
        variables = func["variables"]
        expression = func["expression"]
        vars_str = join(variables, ", ")
        println("$func_name($vars_str) = $expression")
    end
end