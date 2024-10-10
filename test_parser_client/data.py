# Сначала идут 4 TRS и их интерпретации: 1 из головы; 2, 3 и 4 с семинара.
#
# Первая TRS: f(x, h(y)) -> h(f(x, y))
#             g(u(x)) -> h(x)
# Интерпретации: f(x, y) = x^2 + 2 * y
#                g(y) = y + 1
#                h(x) = x + 1
#                u(t) = t + 12
#
# Вторая TRS: f(x, S(y)) -> S(f(x, y))
#             f(x, z) -> x
#             g(x, S(y)) -> f(g(x, y), x)
#             g(x, z) -> z
# Интерпретации: S(x) = x + 1
#                f(x, y) = x + 2 * y
#                g(x, y) = 3 * x * y
#
# Третья TRS: f(x, S(y)) -> S(f(x, y))
#             f(x, z) -> x
# Интерпретации: S(x) = x + 1
#                f(x, y) = x + 2 * y
#
# Четвёртая TRS совпадает с третьей, но переданы интерпретации,
# которые не доказывают завершаемость: S(x) = x + 1
#                                      f(x, y) = x + y
#
# Пятая TRS: f(x, h(x)) -> h(f(x, y))
# Интерпретации: f(x, y) = x^2 + 2 * y
#                h(x) = x + 1
#
# Затем идут первые 3 TRS и пятая TRS (3 и 4 совпадают), но с пустыми интерпретациями
# Такой лютый хардкод из-за того, что парсер ещё не готов

interpret_list = [{
  "functions": [
    {
      "name": "f",
      "variables": ["x", "y"],
      "expression": "(x^2 + 2 * y)"
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
      "variables": ["t"],
      "expression": "(t + 12)"
    }
  ]
}, {
    "functions": [
        {
            "name": "S",
            "variables": ["x"],
            "expression": "(x + 1)"
        },
        {
            "name": "f",
            "variables": ["x", "y"],
            "expression": "(x + 2 * y)"
        },
        {
            "name": "g",
            "variables": ["x", "y"],
            "expression": "(3 * x * y)"
        }
    ]
}, {
  "functions": [
    {
      "name": "f",
      "variables": ["x", "y"],
      "expression": "(x + 2 * y)"
    },
    {
      "name": "S",
      "variables": ["x"],
      "expression": "(x + 1)"
    }
  ]
}, {
    "functions": [
        {
            "name": "f",
            "variables": ["x", "y"],
            "expression": "(x + y)"
        },
        {
            "name": "S",
            "variables": ["x"],
            "expression": "(x + 1)"
        }
    ]
}, {
    "functions": [
        {
            "name": "f",
            "variables": ["x", "y"],
            "expression": "(x^2 + 2 * y)"
        },
        {
            "name": "h",
            "variables": ["x"],
            "expression": "(x + 1)"
        }
    ]
}, {}, {}, {}, {}]

trs_list = [[
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
                            "value": "x",
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
                    "value": "x",
                    "childs": []
                }
            ]
        }
    }
], [
  {
    "left": {
      "value": "f",
      "childs": [
        {
          "value": "x",
          "childs": []
        },
        {
          "value": "S",
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
      "value": "S",
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
      "value": "f",
      "childs": [
        {
          "value": "x",
          "childs": []
        },
        {
          "value": "z",
          "childs": []
        }
      ]
    },
    "right": {
      "value": "x",
      "childs": []
    }
  },
  {
    "left": {
      "value": "g",
      "childs": [
        {
          "value": "x",
          "childs": []
        },
        {
          "value": "S",
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
      "value": "f",
      "childs": [
        {
          "value": "g",
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
        },
        {
          "value": "x",
          "childs": []
        }
      ]
    }
  },
  {
    "left": {
      "value": "g",
      "childs": [
        {
          "value": "x",
          "childs": []
        },
        {
          "value": "z",
          "childs": []
        }
      ]
    },
    "right": {
      "value": "z",
      "childs": []
    }
  }
], [
    {
        "left": {
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "S",
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
            "value": "S",
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
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                     "value": "z",
                     "childs": []
                }
            ]
        },
        "right": {
            "value": "x",
            "childs": []
        }
    }
], [
    {
        "left": {
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "S",
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
            "value": "S",
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
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "z",
                    "childs": []
                }
            ]
        },
        "right": {
            "value": "x",
            "childs": []
        }
    }
], [
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
                            "value": "x",
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
    }
], [
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
                            "value": "x",
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
                    "value": "x",
                    "childs": []
                }
            ]
        }
    }
], [
    {
        "left": {
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "S",
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
            "value": "S",
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
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "z",
                    "childs": []
                }
            ]
        },
        "right": {
            "value": "x",
            "childs": []
        }
    },
    {
        "left": {
            "value": "g",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "S",
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
            "value": "f",
            "childs": [
                {
                    "value": "g",
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
                },
                {
                    "value": "x",
                    "childs": []
                }
            ]
        }
    },
    {
        "left": {
            "value": "g",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "z",
                    "childs": []
                }
            ]
        },
        "right": {
            "value": "z",
            "childs": []
        }
    }
], [
    {
        "left": {
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "S",
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
            "value": "S",
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
            "value": "f",
            "childs": [
                {
                    "value": "x",
                    "childs": []
                },
                {
                    "value": "z",
                    "childs": []
                }
            ]
        },
        "right": {
            "value": "x",
            "childs": []
        }
    }
], [
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
                            "value": "x",
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
    }
]]
