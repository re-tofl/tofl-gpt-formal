import requests
import json

# URL для локального сервера
url_interpretations = 'http://localhost:8081/interpretations'
url_trs = 'http://localhost:8081/trs'

# Первый JSON с данными интерпретаций
interpretations_data = {
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

# Второй JSON с данными TRS
trs_data = [
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
]

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

# Отправка первого JSON на сервер
response_interpretations = requests.post(url_interpretations, json=interpretations_data)
print(f"Interpretations status: {response_interpretations.status_code}")
print(f"Interpretations response: {response_interpretations.text}")

# Отправка второго JSON на сервер
response_trs = requests.post(url_trs, json=trs_data)
print(f"TRS status: {response_trs.status_code}")
print(f"TRS response: {response_trs.text}")
