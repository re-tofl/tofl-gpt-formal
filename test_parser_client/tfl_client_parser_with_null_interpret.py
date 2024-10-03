import requests
import json

# URL для локального сервера
url_interpretations = 'http://localhost:8081/interpretations'
url_trs = 'http://localhost:8081/trs'

# Первый JSON с данными интерпретаций
interpretations_data = {}

# Второй JSON с данными TRS
trs_data = [
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
]

# Отправка первого JSON на сервер
response_interpretations = requests.post(url_interpretations, json=interpretations_data)
print(f"Interpretations status: {response_interpretations.status_code}")
print(f"Interpretations response: {response_interpretations.text}")

# Отправка второго JSON на сервер
response_trs = requests.post(url_trs, json=trs_data)
print(f"TRS status: {response_trs.status_code}")
print(f"TRS response: {response_trs.text}")
