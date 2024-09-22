# Интерпретации функций
interpretations = Dict(
    "f" => (x) -> "($x^2 + $x)",  # f(x, y) = xy + y^2
    "g" => (y) -> "($y + 1)",               # g(y) = y + 1
    "h" => (x) -> "($x^3 + 1)",     # h(x, y) = x^2 + 2y
    "u" => (y) -> "($y + 12)"               # u(y) = y + 12
)

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
                        "value": "f",
                        "childs": [
                            {
                                "value": "x1",
                                "childs": []
                            }
                        ]
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