using JSON
using Symbolics

include("term_generator.jl")
include("Types.jl")

include("run_old_lab.jl")
using .OldLabRunner

include("display_interpretations.jl")
include("server.jl")
include("solver_prepare.jl")

const SMT_PATH = "tmp.smt"

# test funcs
function report_succes(term_pairs, interpretations)
    get_demo(term_pairs, interpretations)
end

function report_failure(term_pairs, interpretations, var_map)
    get_counterexample(term_pairs, interpretations, var_map)
end

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

    println("Полученные переменные и левые части правил после подстановки")
    println(variables_array)
    println(simplified_left_parts)

    make_smt_file(SMT_PATH, variables_array, simplified_left_parts)

    counterexample_vars = get_variables_values_if_sat(SMT_PATH)
    counterexample_vars ≡ nothing ? 
        report_succes(term_pairs, interpretations) :
        report_failure(term_pairs, interpretations, counterexample_vars)
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
