using JSON
using Symbolics

global reply_to_chat = Dict("result" => [])


include("reply_func.jl")
include("term_generator.jl")
include("types.jl")

include("run_old_lab.jl")
using .OldLabRunner

include("display_interpretations.jl")
include("server.jl")
include("solver_prepare.jl")

const SMT_PATH = "tmp.smt"

# Формат ответа в чат
# {
#     "result": [
#         {"format": "code", "data": "..."},
#         {"format": "text", "data": "..."}
#     ]
# }

### Функция для обработки полученных данных
function process_data()

    if json_TRS_string ≡ nothing || json_interpret_string ≡ nothing
        @info "Ожидание данных"
        return
    end

    # Проверяем, предоставлены ли интерпретации
    if json_interpret_string == "{}"
        text_reply("Интерпретации не переданы и, в случае успеха, будут взяты из прошлогодней лабы")

        @info "Интерпретации пусты. Запуск прошлогодней лабы"

        function_symbols = nothing  # Нет информации о функциях из интерпретаций
        # Разбираем TRS без учёта интерпретаций
        term_pairs = get_term_pairs_from_JSON(json_TRS_string, function_symbols)
        separatevars!(term_pairs)

        # Продолжаем с использованием прошлогодней лабораторной работы
        is_sat, interpretations = write_trs_and_run_lab(json_trs_to_string(json_TRS_string), "lab1")
        if is_sat
            text_reply("\nПравила TRS:")

            variables_array, simplified_left_parts = parse_and_interpret(
                term_pairs, interpretations,
            )
            text_reply("\nПравила TRS после подстановки интерпретаций и упрощения:")

            for part ∈ simplified_left_parts
                code_reply("$part -> 0")
            end
            text_reply("\nЗавершаемость доказывается интерпретациями из лабы прошлого года. Демонстрация на случайном терме:")

            println(get_demo(term_pairs, interpretations))
        end

    else
        # Интерпретации предоставлены
        interpretations = parse_interpretations(json_interpret_string)
        function_symbols = Set(keys(interpretations))  # Собираем имена функций

        # Разбираем TRS с учётом function_symbols
        term_pairs = get_term_pairs_from_JSON(json_TRS_string, function_symbols)
        separatevars!(term_pairs)

        text_reply("Интерпретации переданы. Исходные интерпретации:")

        display_interpretations()

        text_reply("\nПравила TRS:")

        # Обрабатываем TRS
        variables_array, simplified_left_parts = parse_and_interpret(
            term_pairs, interpretations,
        )

        text_reply("\nПравила TRS после подстановки интерпретаций и упрощения:")

        for part ∈ simplified_left_parts
            code_reply("$part -> 0")
        end

        make_smt_file(SMT_PATH, variables_array, simplified_left_parts)

        status, counterexample_vars = get_status_and_variables(SMT_PATH)
        if status == Unknown
            println("TRS попроще сделай")
        elseif status == Unsat
            text_reply("\nЗавершаемость доказывается переданными интерпретациями. Демонстрация на случайном терме:")
            println(get_demo(term_pairs, interpretations))
        elseif status == Sat
            println(get_counterexample(term_pairs, interpretations, counterexample_vars))
        else
            println("Ну и ну! Кто-то запорол парсинг ответа солвера")
        end
    end

    #println(JSON.json(reply_to_chat))

    # Наш ответ в чат
    # HTTP.post("https://ivanpavlov2281337.ru/formal_system_reply", [], JSON.json(reply_to_chat))

    # Обнуление для следующего запроса
    global reply_to_chat = Dict("result" => [])

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
