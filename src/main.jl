using JSON
using Symbolics

include("parser/parse_TRS_and_apply_interpretations.jl")
using .Parser

include("display_interpretations.jl")
include("server.jl")

# Функция для обработки полученных данных
function process_data(json_interpret_string, json_TRS_string)
    # Если интерпретации предоставлены, но пустые
    if json_interpret_string == "{}"
        @info "Интерпретации пусты. Запуск лабы деда."
        # Надо будет получить их из лабы дедов
        # interpretations = laba_deda(json_TRS_string)
        return
    else
        display_interpretations()
    end

    # Применение функции переименования переменных в TRS
    json_TRS_string = separatevars(json_TRS_string)

    # Обрабатываем TRS
    variables_array, simplified_left_parts = parse_and_interpret(
        json_TRS_string, json_interpret_string,
    )

    @info "Полученные переменные и левые части правил после подстановки"
    @info variables_array
    @info simplified_left_parts
end

port = 8081
@async begin
    HTTP.serve(request_handler, "0.0.0.0", port)
end

while true
    if isready(interpretation_channel) && isready(trs_channel)
        json_interpret_string = take!(interpretation_channel)
        json_TRS_string = take!(trs_channel)
        process_data(json_interpret_string, json_TRS_string)
    end

    sleep(1)
end