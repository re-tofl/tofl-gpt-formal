using HTTP

global json_interpretation_string
global json_TRS_string   
# Функция для обработки входящих запросов
function request_handler(req)
    if req.method == "POST"
        path = String(req.target)
        body = String(req.body)  # Получаем JSON-строку

        if path == "/interpretations"
            json_interpretation_string = body
            println("Получены интерпретации.")
            return HTTP.Response(200, "Интерпретации получены.")
        elseif path == "/trs"
            json_TRS_string = body
            println("Получены данные TRS.")
            return HTTP.Response(200, "Данные TRS получены.")
        else
            return HTTP.Response(404, "Неизвестный путь.")
        end
    else
        return HTTP.Response(405, "Метод не поддерживается.")
    end
end
