using JSON
using Symbolics

######################### Structures
# Structure for terms
struct Term
    name::String
    childs::Vector{Term}
end

########################## JSON Data
# Hardcoded JSON string with functions f, g, h, u
json_interpret = """
{
  "functions": [
    {
      "name": "f",
      "variables": ["x", "y", "z"],
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

# Example JSON containing the left and right parts of the TRS
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

########################## Function to Display Interpretations
function display_interpretations()
    parsed_data = JSON.parse(json_interpret)
    println("Исходные интерпретации:")
    for func in parsed_data["functions"]
        func_name = func["name"]
        variables = split(func["variables"][1], ", ")  # Split variables by commas
        expression = func["expression"]
        vars_str = join(variables, ", ")
        println("$func_name($vars_str) = $expression")
    end
    println()
end

########################## Function to Parse and Interpret TRS
function parse_and_interpret(json_string::String, interpretations::Dict{String, Function})
    parsed_json = JSON.parse(json_string)

    # Parse the left and right parts of the TRS
    left_term = parse_term(parsed_json[1])
    right_term = parse_term(parsed_json[2])

    # Create a var_map dictionary that maps variables from TRS to variables in interpretations
    var_map = Dict{String, String}()

    # Collect variables from the TRS and add them to var_map
    variable_names = Set{String}()
    function collect_vars(term::Term)
        if isempty(term.childs)
            # If the term is a variable, add its name to var_map and variable_names
            var_map[term.name] = term.name
            push!(variable_names, term.name)
        else
            # The term is a function, process its children
            for child in term.childs
                collect_vars(child)
            end
        end
    end

    # Collect variables from left and right terms
    collect_vars(left_term)
    collect_vars(right_term)

    # Now, declare variables dynamically
    # Convert variable names to Symbols
    variable_symbols = Symbol.(collect(variable_names))
    # Declare variables with Symbolics.@variables using @eval
    @eval @variables $(variable_symbols...)

    # Parse interpretations with variables from TRS, passing var_map
    parse_interpretations(interpretations, var_map)

    # Apply interpretation to left and right parts of TRS
    interpreted_left = apply_interpretation(left_term, interpretations, var_map)
    interpreted_right = apply_interpretation(right_term, interpretations, var_map)

    # Output the TRS rule in human-readable form
    left_term_str = term_to_string(left_term)
    right_term_str = term_to_string(right_term)
    println("\nПравило TRS:")
    println("$left_term_str -> $right_term_str")

    # Parse the interpreted expressions into Symbolics expressions
    left_expr = Symbolics.simplify(eval(Meta.parse(interpreted_left)))
    right_expr = Symbolics.simplify(eval(Meta.parse(interpreted_right)))

    # Compute the difference and simplify
    difference = Symbolics.simplify(left_expr - right_expr)

    # Output the simplified expression
    println("\nУпрощенное выражение:")
    println("$(left_expr) = $(right_expr)")
    println("После упрощения:")
    println("$(difference) = 0")
end

########################## Function to Parse Interpretations
function parse_interpretations(interpretations::Dict{String, Function}, var_map::Dict{String, String})
    parsed_data = JSON.parse(json_interpret)

    for func in parsed_data["functions"]
        func_name = func["name"]
        variables = split(func["variables"][1], ", ")  # Split variables by commas
        expression = func["expression"]

        # Create a function with the required number of variables
        interpretations[func_name] = (vars...) -> begin
            expr = expression
            # Replace variables in the expression with corresponding variables from TRS (var_map)
            for (i, var) in enumerate(variables)
                expr = replace(expr, var => vars[i])  # Use TRS variables
            end
            return expr
        end
    end
end

########################################## Function to Parse Terms
# Function to parse terms from JSON
function parse_term(json::Dict)
    childs = [parse_term(child) for child in json["childs"]]
    return Term(json["value"], childs)
end

# Function to display a term in human-readable form
function term_to_string(term::Term)
    if isempty(term.childs)
        return term.name  # If the term is a variable, return its name
    else
        # Recursively process child terms
        child_strings = [term_to_string(child) for child in term.childs]
        return "$(term.name)(" * join(child_strings, ", ") * ")"  # Assemble the string in the format f(x, g(y))
    end
end

############################ Function for Applying Interpretations
function apply_interpretation(term::Term, interpretations::Dict{String, Function}, var_map::Dict{String, String})
    if isempty(term.childs)
        # If it's a variable, return its name
        return term.name
    else
        # Apply the interpretation for the function
        interpreted_childs = [apply_interpretation(child, interpretations, var_map) for child in term.childs]
        if haskey(interpretations, term.name)
            interp_func = interpretations[term.name]
            # Call the interpretation function with substituted child terms
            return interp_func(interpreted_childs...)
        else
            return "$(term.name)(" * join(interpreted_childs, ", ") * ")"
        end
    end
end

########################### Main Code Execution
# Display the original interpretations
display_interpretations()

# Create an empty dictionary for interpretations
interpretations = Dict{String, Function}()

# Parse and interpret the first TRS rule
parse_and_interpret(json_string_first, interpretations)

# Parse and interpret the second TRS rule
parse_and_interpret(json_string_second, interpretations)
