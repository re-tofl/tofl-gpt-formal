using HTTP

interpretation_channel = Channel{String}()
trs_channel = Channel{String}()   
# Функция для обработки входящих запросов
function request_handler(req)
    if req.method == "POST"
        path = String(req.target)
        body = String(req.body)  # Получаем JSON-строку

        if path == "/interpretations"
            put!(interpretation_channel, body)
            println("Получены интерпретации.")
            return HTTP.Response(200, "Интерпретации получены.")
        elseif path == "/trs"
            put!(trs_channel, body)
            println("Получены данные TRS.")
            return HTTP.Response(200, "Данные TRS получены.")
        else
            return HTTP.Response(404, "Неизвестный путь.")
        end
    else
        return HTTP.Response(405, "Метод не поддерживается.")
    end
end
