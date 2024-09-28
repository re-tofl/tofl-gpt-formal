using JSON
using Symbolics
include(joinpath(@__DIR__,"structures.jl"))
include(joinpath(@__DIR__,"data/jsons_data.jl"))
include(joinpath(@__DIR__,"parser/parse_interpretations.jl"))
include(joinpath(@__DIR__,"parser/parse_TRS_and_apply_interpretations.jl"))
include(joinpath(@__DIR__,"display_interpretations.jl"))
include(joinpath(@__DIR__,"server.jl"))

global variables_array = Vector{String}() # Вектор с итоговым набором переменых
global simplified_left_parts = Vector{String}() # Вектор с итоговым набором левых частей правил

interpretations = Dict{String, Function}()
# Функция для обработки полученных данных
function process_data()
    # Проверяем, получены ли оба JSONа
    if json_TRS_string === nothing || json_interpret_string === nothing
        println("Ожидание данных...")
        return
    end

    # Применение функции переименования переменных в TRS
    json_TRS_string = separatevars(json_TRS_string)

    # Если интерпретации предоставлены, но пустые
    if json_interpret_string == "{}"
        println("Интерпретации пусты. Запуск лабы деда.")
        # Надо будет получить их из лабы дедов
        # interpretations = laba_deda(json_TRS_string)
        return
    else
        display_interpretations()
    end

    # Обрабатываем TRS
    parse_and_interpret(json_TRS_string, interpretations)

    println("\nПолученные переменные и левые части правил после подстановки")
    println(variables_array)
    println(simplified_left_parts)

    # Очищаем данные после обработки
    global json_TRS_string = nothing
    global json_interpret_string = nothing
end

port = 8081
@async begin
    HTTP.serve(request_handler, "0.0.0.0", port)
end
println("Сервер запущен на порту $port")

# Главный цикл программы
while true
    process_data()
    sleep(1)
end