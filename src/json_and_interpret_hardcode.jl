# Интерпретации функций
# interpretations_dict = Dict(
#     "f" => (x) -> "($x^2 + $x)",  # f(x, y) = xy + y^2
#     "g" => (y) -> "($y + 1)",               # g(y) = y + 1
#     "h" => (x) -> "($x^3 + 1)",     # h(x, y) = x^2 + 2y
#     "u" => (y) -> "($y + 12)"               # u(y) = y + 12
# )

# Захардкоженная JSON строка с функциями f и g
json_interpret = """
{
  "functions": [
    {
      "name": "f",
      "variables": ["x, y, z"],
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

# Пример JSON, содержащий левую и правую часть TRS
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