# include("parser/parse_TRS_and_apply_interpretations.jl")
include("solver_prepare.jl")
include("term_generator.jl")

using JSON
using .Parser

# include("common/Types.jl")
using .Types

json_interpret_hardcode = """
{
  "functions": [
    {
      "name": "f",
      "variables": ["x", "y"],
      "expression": "(x + 2 * y)"
    },
    {
      "name": "g",
      "variables": ["y"],
      "expression": "(y + 1)"
    },
    {
      "name": "h",
      "variables": ["x"],
      "expression": "(x + 1)"
    },
    {
      "name": "u",
      "variables": ["y"],
      "expression": "(y + 12)"
    }
  ]
}
"""

json_TRS_hardcode = """
[
    {
        "left": {
            "value": "f",
            "childs": [
                {
                    "value": "x1",
                    "childs": []
                },
                {
                    "value": "h",
                    "childs": [
                        {
                            "value": "x2",
                            "childs": []
                        }
                    ]
                }
            ]
        },
        "right": {
            "value": "h",
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
                        }
                    ]
                }
            ]
        }
    },
    {
        "left": {
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
        "right": {
            "value": "h",
            "childs": [
                {
                    "value": "y2",
                    "childs": []
                }
            ]
        }
    }
]
"""
sep = separatevars(json_TRS_hardcode)
variables_array, simplified_left_parts = parse_and_interpret(sep, json_interpret_hardcode)
make_smt_file("test.smt", variables_array, simplified_left_parts)
vars = Dict{Any, Any}("x2_1" => "1", "x2_2" => "1", "x1_1" => "1", "y2_2" => "13")

interpretations = Parser.parse_interpretations(json_interpret_hardcode)

term_pairs = Vector()
parsed_json = JSON.parse(sep)
    # Проходим по каждому правилу в массиве
for rule ∈ parsed_json
    # Парсим левую и правую части правила
    left_term = Parser.make_term_from_json(rule["left"])
    right_term = Parser.make_term_from_json(rule["right"])
    @show left_term
    @show right_term
    push!(term_pairs, (left_term, right_term))
end
# @info interpretations
# @info vars
println(check_counterexample(term_pairs, interpretations, vars))