using HTTP
using JSON
include("process_data.jl")
# Глобальные переменные для хранения полученных JSON-строк
global json_TRS_string = nothing
global json_interpret_string = nothing

global reply_to_chat = Dict("result" => [])

function request_handler(req)

    # Обнуление для следующего запроса
    global reply_to_chat = Dict("result" => [])

    global json_TRS_string = nothing
    global json_interpret_string = nothing

    if req.method == "POST"
        path = String(req.target)
        body = String(req.body)

        if path == "/data"
            try
                # Парсим JSON тело
                parsed_body = JSON.parse(body)

                # Извлекаем json_TRS и json_interpret
                global json_TRS_string = JSON.json(parsed_body["json_TRS"])
                global json_interpret_string = JSON.json(parsed_body["json_interpret"])

                println("Получены данные TRS и интерпретации.")
                println("TRS:", json_TRS_string)
                println("Интерпретации:", json_interpret_string)

                return HTTP.Response(200, process_data())
            catch e
                println("Ошибка при обработке данных: ", e)
                return HTTP.Response(400, "Ошибка при обработке данных: $e")
            end
        else
            return HTTP.Response(404, "Неизвестный путь.")
        end
    else
        return HTTP.Response(405, "Метод не поддерживается.")
    end
end

