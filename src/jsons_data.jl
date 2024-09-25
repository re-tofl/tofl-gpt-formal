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