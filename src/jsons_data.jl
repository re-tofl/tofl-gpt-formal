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