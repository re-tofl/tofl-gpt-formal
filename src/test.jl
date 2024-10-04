# include("parser/parse_TRS_and_apply_interpretations.jl")
include("solver_prepare.jl")
include("term_generator.jl")
include("Types.jl")
# include("parser/parse_TRS_and_apply_interpretations.jl")

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
parsed_TRS = get_term_pairs_from_JSON(json_TRS_hardcode)
separatevars!(parsed_TRS)
variables_array, simplified_left_parts = parse_and_interpret(parsed_TRS, parse_interpretations(json_interpret_hardcode))
make_smt_file("test.smt", variables_array, simplified_left_parts)
vars = Dict{Any, Any}("x2_1" => "1", "x2_2" => "1", "x1_1" => "1", "y2_2" => "13")

interpretations = parse_interpretations(json_interpret_hardcode)

# @info interpretations
# @info vars
# println(check_counterexample(term_pairs, interpretations, vars))
# @show term_to_string(build_example_term(parsed_TRS))
t = Term(
    "f",
    [
        Term(
            "g",
            [
                Term(
                    "f",
                    [Term("x", []), Term("y", [])]
                )
            ]
        ),
        Term(
            "g",
            [Term("y", Vector())]
        )
    ]
)

trs = [(Term("f", [Term("g", [Term("x", [])]), Term("y", [])]), Term("g", [Term("y", [])]))]
@show term_to_string(trs[1][1])
@show term_to_string(trs[1][2])
@show term_to_string(t)

# f(g(f(x, y)), g(y))
# f(g(x), y) -> g(y)
t = rewrite_term(t, trs)
expr = apply_interpretation(t, interpretations)
vars = collect_vars
var_map = random

@show t