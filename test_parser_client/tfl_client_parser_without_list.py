import requests
import json

# URL для локального сервера
url_data= 'http://localhost:8081/data'

data = {
    "json_TRS": [
        {
            "left": {
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
            },
            "right": {
                "value": "k",
                "childs": []
            }
        }
    ],
    "json_interpret": {
        "functions": [
            {
                "name": "f",
                "variables": ["x", "y"],
                "expression": "(x * y)"
            },
            {
                "name": "k",
                "variables": [],
                "expression": "(5)"
            }
        ]
    }
}

trs_data2 = [
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
]

# Отправка JSON на сервер
response_interpretations = requests.post(url_data, json=data)
print(f"Interpretations status: {response_interpretations.status_code}")
print(f"Interpretations response: {response_interpretations.text}")

