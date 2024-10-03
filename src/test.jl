include("parser/parse_TRS_and_apply_interpretations.jl")
include("solver_prepare.jl")

using .Parser

# include("common/Types.jl")
# using ..Types

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
variables_array, simplified_left_parts = parse_and_interpret(json_TRS_hardcode, json_interpret_hardcode)
make_smt_file("test.smt", variables_array, simplified_left_parts)
vars = @show get_variables_values_if_sat("test.smt")