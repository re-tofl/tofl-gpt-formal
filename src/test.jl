# include("parser/parse_TRS_and_apply_interpretations.jl")
include("solver_prepare.jl")
include("term_generator.jl")
# include("common/Types.jl")
# include("parser/parse_TRS_and_apply_interpretations.jl")

using Main.Types
using Main.Parser
using JSON

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
parsed_TRS = Parser.get_term_pairs_from_JSON(json_TRS_hardcode)
Parser.separatevars!(parsed_TRS)
variables_array, simplified_left_parts = parse_and_interpret(parsed_TRS, Parser.parse_interpretations(json_interpret_hardcode))
make_smt_file("test.smt", variables_array, simplified_left_parts)
vars = Dict{Any, Any}("x2_1" => "1", "x2_2" => "1", "x1_1" => "1", "y2_2" => "13")

interpretations = Parser.parse_interpretations(json_interpret_hardcode)

# @info interpretations
# @info vars
# println(check_counterexample(term_pairs, interpretations, vars))
@show replace_random_leaf(parsed_TRS[1][1], Types.Term("q", Vector()))