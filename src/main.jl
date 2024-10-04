using JSON
using Symbolics

include("term_generator.jl")
include("Types.jl")

include("run_old_lab.jl")
using .OldLabRunner

include("display_interpretations.jl")
include("server.jl")

# Функция для обработки полученных данных
function process_data()
    if json_TRS_string ≡ nothing || json_interpret_string ≡ nothing
        @info "Ожидание данных"
        return
    end

    # Если интерпретации предоставлены, но пустые
    if json_interpret_string == "{}"
        @info "Интерпретации пусты. Запуск лабы деда."

        write_trs_and_run_lab(json_trs_to_string(json_TRS_string), "lab1")
        global json_TRS_string = nothing
        global json_interpret_string = nothing
        return
    end

    term_pairs = get_term_pairs_from_JSON(json_TRS_string)
    separatevars!(term_pairs)
    interpretations = parse_interpretations(json_interpret_string)
    # Применение функции переименования переменных в TRS
    display_interpretations()
    # Обрабатываем TRS
    variables_array, simplified_left_parts = parse_and_interpret(
        term_pairs, interpretations,
    )

    @info "Полученные переменные и левые части правил после подстановки"
    @info variables_array
    @info simplified_left_parts

    # Здесь вы должны вызвать SMT-солвер и проверить завершаемость
    # Предположим, что солвер подтвердил завершаемость
    # solver_result = true  # Замените на реальный результат

    # if solver_result
    #     # После получения подтверждения от SMT-солвера
    #     # Парсим правила TRS из JSON-строки
    #     parsed_json = JSON.parse(json_TRS_string)

    #     # Явно приводим к нужному типу
    #     # trs_rules = Vector{Dict{String, Any}}(parsed_json)

    #     # # Генерируем случайный терм
    #     # random_term = generate_random_term(trs_rules)
    #     # println("\nСгенерированный случайный терм:")
    #     # println(term_to_string(random_term))

    #     # # Переписываем терм согласно правилам TRS
    #     # rewritten_term = rewrite_term(random_term, trs_rules)
    #     # println("\nПереписанный терм:")
    #     # println(term_to_string(rewritten_term))
    # end

    # Очищаем данные после обработки
    global json_TRS_string = nothing
    global json_interpret_string = nothing
end

port = 8081
@async begin
    HTTP.serve(request_handler, "0.0.0.0", port)
end

while true
    process_data()
    sleep(1)
end
