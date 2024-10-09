using JSON
using Symbolics

const default_reply = []
global reply_to_chat = default_reply


include("reply_macros.jl")
include("term_generator.jl")
include("types.jl")

include("run_old_lab.jl")
using .OldLabRunner

include("display_interpretations.jl")
include("server.jl")
include("solver_prepare.jl")

const SMT_PATH = "tmp.smt"


# {
#     "result": [
#         {"format": "code", "data": "..."},
#         {"format": "text", "data": "..."}
#     ]
# }

# Функция для обработки полученных данных
function process_data()

    if json_TRS_string ≡ nothing || json_interpret_string ≡ nothing
        @info "Ожидание данных"
        return
    end

    term_pairs = get_term_pairs_from_JSON(json_TRS_string)
    separatevars!(term_pairs)

    # Если интерпретации предоставлены, но пустые
    if json_interpret_string == "{}"


        # global reply_to_chat = string(
        #     reply_to_chat,
        #     "{\"format\": \"text\", \"data\": \"",
        #     "Интерпретации не переданы и, в случае успеха, будут взяты из прошлогодней лабы\"}, "
        # )

        text_reply("Интерпретации не переданы и, в случае успеха, будут взяты из прошлогодней лабы")

        @info "Интерпретации пусты. Запуск прошлогодней лабы"

        is_sat, interpretations = write_trs_and_run_lab(json_trs_to_string(json_TRS_string), "lab1")
        if is_sat

            # global reply_to_chat = string(
            #     reply_to_chat,
            #     "{\"format\": \"text\", \"data\": \"",
            #     "Правила TRS:\\n\"}, "
            # )

            text_reply("Правила TRS:")

            variables_array, simplified_left_parts = parse_and_interpret(
                term_pairs, interpretations,
            )

            # global reply_to_chat = string(
            #     reply_to_chat,
            #     "{\"format\": \"text\", \"data\": \"",
            #     "Правила TRS после упрощения:\\n\"}, "
            # )
            text_reply("Правила TRS после упрощения:")

            for part ∈ simplified_left_parts
                # global reply_to_chat = string(
                #     reply_to_chat,
                #     "{\"format\": \"code\", \"data\": \"",
                #     "$part -> 0\"}, "
                # )
                code_reply("$part -> 0")
            end

            # global reply_to_chat = string(
            #     reply_to_chat,
            #     "{\"format\": \"text\", \"data\": \"",
            #     "\\nДемонстрация на случайном терме:\"}, "
            # )

            text_reply("Демонстрация на случайном терме:")

            println(get_demo(term_pairs, interpretations))
        end

    else

        # global reply_to_chat = string(
        #     reply_to_chat,
        #     "{\"format\": \"text\", \"data\": \"",
        #     "Интерпретации переданы. Исходные интерпретации:\"}, "
        # )

        text_reply("Интерпретации переданы. Исходные интерпретации:")

        interpretations = parse_interpretations(json_interpret_string)
        display_interpretations()

        # global reply_to_chat = string(
        #     reply_to_chat,
        #     "{\"format\": \"text\", \"data\": \"",
        #     "Правила TRS:\\n\"}, "
        # )

        text_reply("Правила TRS:")
        
        # Обрабатываем TRS
        variables_array, simplified_left_parts = parse_and_interpret(
            term_pairs, interpretations,
        )

        # global reply_to_chat = string(
        #     reply_to_chat,
        #     "{\"format\": \"text\", \"data\": \"",
        #     "Правила TRS после упрощения:\\n\"}, "
        # )

        text_reply("Правила TRS после упрощения:")

        for part ∈ simplified_left_parts
            # global reply_to_chat = string(
            #     reply_to_chat,
            #     "{\"format\": \"code\", \"data\": \"",
            #     "$part -> 0\"}, "
            # )
            code_reply("$part -> 0")
        end

        make_smt_file(SMT_PATH, variables_array, simplified_left_parts)

        status, counterexample_vars = get_status_and_variables(SMT_PATH)
        if status == Unknown
            println("TRS попроще сделай")
        elseif status == Unsat
            println(get_demo(term_pairs, interpretations))
        elseif status == Sat
            println(get_counterexample(term_pairs, interpretations, counterexample_vars))
        else
            println("Ну и ну! Кто-то запорол парсинг ответа солвера")
        end
    end

    # global reply_to_chat = string(
    #     reply_to_chat,
    #     "]}"
    # )

    # Удалил лишнюю запятую
    # global reply_to_chat = reply_to_chat[1:end-4] * reply_to_chat[end-2:end]

    println(JSON.json(reply_to_chat))

    # Наш ответ в чат
    # HTTP.post("https://ivanpavlov2281337.ru/formal_system_reply", [], JSON.json(reply_to_chat))

    # Обнуление для следующего запроса
    global reply_to_chat = default_reply

    # Пока так
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
