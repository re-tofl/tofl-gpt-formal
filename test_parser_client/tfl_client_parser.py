from time import sleep

import requests
from data import data_list

# URL для локального сервера
url_data = 'http://localhost:8081/data'

for i in range(len(data_list)):
    # Отправка первого JSON на сервер
    response_interpretations = requests.post(url_data, json=data_list[i])
    print(f"Interpretations status: {response_interpretations.status_code}")
    print(f"Interpretations response: {response_interpretations.text}")
