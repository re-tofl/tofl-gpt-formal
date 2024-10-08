using JSON
using Symbolics
using Defer

include("term_generator.jl")
include("types.jl")

include("run_old_lab.jl")
using .OldLabRunner

include("display_interpretations.jl")
include("server.jl")
include("solver_prepare.jl")

const SMT_PATH = "tmp.smt"

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
        @info "Интерпретации пусты. Запуск лабы деда."

        is_sat, interpretations = write_trs_and_run_lab(json_trs_to_string(json_TRS_string), "lab1")
        if is_sat
            variables_array, simplified_left_parts = parse_and_interpret(
                term_pairs, interpretations,
            )
            println("Полученные переменные и левые части правил после подстановки")
            println(variables_array)
            println(simplified_left_parts)
            println(get_demo(term_pairs, interpretations))
        end
    else
        interpretations = parse_interpretations(json_interpret_string)
        display_interpretations()
        # Обрабатываем TRS
        variables_array, simplified_left_parts = parse_and_interpret(
            term_pairs, interpretations,
        )

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
