using JSON
using Symbolics

include("parser/parse_TRS_and_apply_interpretations.jl")
using .Parser

include("data/jsons_data.jl")
include("display_interpretations.jl")
include("server.jl")

include("data/jsons_data.jl")

json_TRS_string = json_TRS_hardcode
json_interpret_string = json_interpret_hardcode
interpretations = Dict{String, Function}()
# Функция для обработки полученных данных
function process_data()
    # Проверяем, получены ли оба JSONа
    if json_TRS_string ≡ nothing || json_interpret_string ≡ nothing
        @info "Ожидание данных..."
        return
    end

    # Применение функции переименования переменных в TRS
    json_TRS_string = separatevars(json_TRS_string)

    # Если интерпретации предоставлены, но пустые
    if json_interpret_string == "{}"
        @info "Интерпретации пусты. Запуск лабы деда."
        # Надо будет получить их из лабы дедов
        # interpretations = laba_deda(json_TRS_string)
        return
    else
        display_interpretations()
    end

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

# Главный цикл программы
while true
    process_data()
    sleep(1)
end