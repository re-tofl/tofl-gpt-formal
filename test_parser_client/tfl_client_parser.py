from time import sleep

import requests
from data import interpret_list, trs_list

# URL для локального сервера
url_interpretations = 'http://localhost:8081/interpretations'
url_trs = 'http://localhost:8081/trs'

for i in range(len(trs_list)):
    # Отправка первого JSON на сервер
    response_interpretations = requests.post(url_interpretations, json=interpret_list[i])
    print(f"Interpretations status: {response_interpretations.status_code}")
    print(f"Interpretations response: {response_interpretations.text}")

    # Отправка второго JSON на сервер
    response_trs = requests.post(url_trs, json=trs_list[i])
    print(f"TRS status: {response_trs.status_code}")
    print(f"TRS response: {response_trs.text}\n")

    # В чате будет реализован нормальный функционал ожидания ответа
    sleep(20)
