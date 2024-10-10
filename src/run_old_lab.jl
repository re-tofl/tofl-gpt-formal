module OldLabRunner

include("reply_func.jl")

using Base.Sys
using Symbolics
    
export write_trs_and_run_lab

### Ищем папку проекта на go folder_name c исполняемым файлом name_file (без расширения)
### Собираем проект или используем существующий исполняемый файл
function build_or_not(folder_name, name_file)
    current_dir = pwd()
    dirs_to_check = [current_dir, dirname(current_dir)]
    folder_path = ""

    # Ищем нужную папку в текущем и родительском каталогах
    for dir ∈ dirs_to_check
        if isdir(joinpath(dir, folder_name))
            folder_path = joinpath(dir, folder_name)
        end
    end

    postfixes = [".exe", ""]
    is_found = false
    file_path = ""

    # Проверяем наличие искомого исполняемого файла
    for postfix ∈ postfixes
        target_file = name_file * postfix
        file_path = joinpath(folder_path, target_file)
        
        if (isfile(file_path) && isexecutable(file_path))
            is_found = true
            @info "Будет использован '$file_path'"
            break
        end
    end

    if !(is_found)
        @info "Файл '$name_file' не найден. Выполняем команду 'go build .'"
        cd(folder_path) do
            read(run(`go build .`), )
        end
        for postfix ∈ postfixes
            target_file = name_file * postfix
            file_path = joinpath(folder_path, target_file)
            if (isfile(file_path) && isexecutable(file_path))
                is_found = true
                @info "Будет использован '$file_path'"
                break
            end
        end
    end

    return "$file_path"
end

### Запуск лабы и перенаправление вывода
function interact_with_program(path)
    output = ""
    try
        output = open(`$path`, "r+") do io
            write(io, "2\n")
            read(io, String)
        end
    catch
        text_reply("Лаба Вячеслава сломалась :( Попробуйте другие TRS или добавьте интерпретации")

        print("Лаба Вячеслава сломалась :( \nПопробуйте другие TRS или добавьте интерпретации\n")
        return true, output
    end

    return false, output
end


function parse_interpretations(input)
    lines = split(input, "\n")
    constructors = Dict()
    for line ∈ lines
        line_parts = split(line, ",")
        name_constr = line_parts[1][end:end]
        arguments = replace(line_parts[end], "constants: {Dimensionality:" => "", "Constants:[" => "", "]}" => "")
        arguments = split(strip(arguments, ' '), " ")
        constructors[name_constr] = arguments
    end

    return constructors    
end


function parse_smt_output(smt_answer)
    found_values = Dict{}()
    is_sat = false
    if startswith(smt_answer, "sat")
        is_sat = true
        lines = eachmatch(r"(\w+\d+)*\s*\(\)\s*Int\s+\d+", smt_answer)
        for pattern ∈ lines
            splited_pattern = split(pattern.match, " ")
            variable = splited_pattern[1]
            value = splited_pattern[end]
            found_values[variable] = value
        end  
    end

    return is_sat, found_values
end

### Подстановка найденных значений коэффициентов линейной интерпретации
function substitute_coefs(expressions::Dict, replacements)
    simplified_expr = expressions
    for (name, attr) ∈ expressions
        for i ∈ eachindex(attr)
            new_coef = attr[i]
            name_coefs = eachmatch(r"\w\_\d*", new_coef)
            for m ∈ name_coefs
                new_coef = replace(new_coef, m.match => replacements[m.match])
            end
            simplified_expr[name][i] = new_coef
        end
    end
    return simplified_expr
end

### Для вывода лабы
function parse_output(output)
    needed_part = strip(split(output, "constructor and constants:")[end], [' ', '\n'])
    interpret_constr = strip(split(needed_part, "variables:")[1], [' ', '\n'])
    needed_part = strip(split(needed_part, "after similar ones:")[end], [' ', '\n'])
    smtout = strip(split(needed_part, "Результат выполнения команды:")[end], [' ', '\n'])

    is_sat, vars_values = parse_smt_output(smtout)
    constructors = parse_interpretations(interpret_constr)
    
    if is_sat
        constructors = substitute_coefs(constructors, vars_values)       
    end
    
    return is_sat, constructors
end

### Для строкового представления слагаемых
function add_monom(result_string_part, var, coef)
    if result_string_part == ""
        result_string_part  *= "$coef" * ((var == "") ? "" : " * " * var)
    else
        result_string_part  *= " + " * "$coef" * ((var == "") ? "" : " * " * var)
    end
    return result_string_part
end

### Для вывода интерпретаций
function construct_to_string(dict_constr)
    result_string = ""
    for (name, attr) ∈ dict_constr
        result_string *= name * "("
        count_vars = parse(Int, attr[1])
        variables = join(["x$i" for i in 1:count_vars], ", ")
        result_string *= variables * ") = "

        right_part = ""
        for i ∈ length(attr):-1:2
            if i == 2
                right_part = add_monom(right_part, "", attr[i])
            else
                right_part = add_monom(right_part, "x"*"$(i-2)", attr[i])
            end
        end
        result_string *= right_part * "\n"
    end
    
    #return strip(result_string, '\n')
    result_string
end

### Приводим полученные интерпретации к виду, который
### используется в основной части
function constructors_to_func(constructors)
    interpretations::Dict{String, Function} = Dict()

    for (name, attr) ∈ constructors
        variables = ["x$i" for i in 1:parse(Int, attr[1])]
        expression = ""

        for i ∈ length(attr):-1:2
            if i == 2
                expression = add_monom(expression, "", attr[i])
            else
                expression = add_monom(expression, "x"*"$(i-2)", attr[i])
            end
        end
        expression = "(" * expression * ")"

        # Создаем функцию с необходимым количеством переменных
        interpretations[name] = (vars...) -> begin
            expr = expression
            for (i, var) ∈ enumerate(variables)
                expr = replace(expr, Regex("\\b$(var)\\b") => vars[i])
            end
            return expr
        end
    end

    interpretations
end


### Основная функция: готовим файл ввода для лабы и ищем путь к ней
function write_trs_and_run_lab(trs_vector_of_strings, name_folder, name_file=name_folder)
    trs_string = join(trs_vector_of_strings, "\n")

    open("fileRead.txt", "w") do wtf 
        write(wtf, trs_string) 
    end
    err, output = interact_with_program(build_or_not(name_folder, name_file))

    if err
        return false, false
    end

    if length(split(output, "команды:\n")[end]) < 3

        text_reply("Проверьте наличие z3")

        println("Проверьте наличие z3")
        return false, false
    end
    
    is_sat, constructors = parse_output(output)
    if is_sat
        text_reply("\nЕсть линейная интерпретация, показывающая завершаемость TRS")
        code_reply("$(construct_to_string(constructors))")

        println("Есть линейная интерпретация, показывающая завершаемость TRS")
        println(construct_to_string(constructors))
    else
        text_reply("Линейными интерпретациями не удается доказать завершаемость TRS")

        println("Линейными интерпретациями не удается доказать завершаемость TRS")
    end
    return is_sat, constructors_to_func(constructors)
end

end
