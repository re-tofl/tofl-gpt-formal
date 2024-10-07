# include("parser/parse_TRS_and_apply_interpretations.jl")
include("solver_prepare.jl")
include("term_generator.jl")
include("Types.jl")
include("parse_TRS_and_apply_interpretations.jl")

using JSON
using Defer

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
      "expression": "(y + 2)"
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
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "h",
                    "childs": [
                        {
                            "value": "y",
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
                            "value": "x",
                            "childs": []
                        },
                        {
                            "value": "y",
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
SMT_PATH = "tmp.smt"

term_pairs = get_term_pairs_from_JSON(json_TRS_hardcode)
separatevars!(term_pairs)
interpretations = parse_interpretations(json_interpret_hardcode)
# Применение функции переименования переменных в TRS
# Обрабатываем TRS
variables_array, simplified_left_parts = parse_and_interpret(
    term_pairs, interpretations,
)

make_smt_file(SMT_PATH, variables_array, simplified_left_parts)

status, counterexample_vars = get_status_and_variables(SMT_PATH)
if status == Unknown
    println("TRS попроще сделай")
elseif status == Unsat
    println(get_demo(term_pairs, interpretations))
elseif status == Sat
    println(get_counterexample(term_pairs, interpretations, counterexample_vars))
else
    println("Ну и ну! Кто-то запорол парсинг ответа солвера")
end