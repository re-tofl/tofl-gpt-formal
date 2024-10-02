module Old_Lab_Runner

using Base.Sys
using Symbolics
    
export write_trs_and_run_lab

function build_or_not(folder_name, name_file)
    current_dir = pwd()
    dirs_to_check = [current_dir, dirname(current_dir)]
    folder_path = ""

    for dir in dirs_to_check
        if isdir(joinpath(dir, folder_name))
            folder_path = joinpath(dir, folder_name)
        end
    end

    postfixes = [".exe", ""]
    is_found = false
    file_path = ""
    for postfix in postfixes
        target_file = name_file * postfix
        file_path = joinpath(folder_path, target_file)
        # Проверяем наличие искомого исполняемого файла
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
        for postfix in postfixes
            target_file = name_file * postfix
            file_path = joinpath(folder_path, target_file)
            # Проверяем наличие искомого исполняемого файла
            if (isfile(file_path) && isexecutable(file_path))
                is_found = true
                @info "Будет использован '$file_path'"
                break
            end
        end
    end

    return "$file_path"
end


function interact_with_program(path)
    io = open(`$path`; write=true, read=true)
    write(io, "2\n")
    output = read(io, String)

    open("old_lab_output.txt", "w") do wtf 
        write(wtf, output) 
    end

    close(io)
    return output
end


function parse_map(input)
    cleaned_string = replace(input, "map[" => "")[1:end-1]
    result_dict = Dict{String, String}()

    # Разбиение по пробелам
    pairs = split(cleaned_string, r"\s+(?=\w+:)")
    
    for pair in pairs
        # Разделение ключа и значения по двоеточию
        key_value = split(pair, ":")
        
        if length(key_value) == 2
            key = strip(key_value[1])
            result_dict[key] = strip(replace(key_value[2], r"^\[\s*" => "", r"\s*\]$" => ""))
        end
    end

    return result_dict    
end


function parse_expr(input)
    sections = split(input, "\n")
    num_sections = length(sections)
    
    all_expr = Vector{Vector{Dict{String, Any}}}(undef, div(num_sections, 3))

    index = 0
    for section in sections
        if startswith(section, r"\d+")
            index += 1
            all_expr[index] = [Dict{String, Any}(), Dict{String, Any}()]
        elseif startswith(section, "left")
            all_expr[index][1] = parse_map(section[6:end])
        elseif startswith(section, "right")
            all_expr[index][2] = parse_map(section[7:end])
        else 
            println("Этого не могло случиться О_о")
        end
    end

    return all_expr
end


function parse_interpretations(input)
    lines = split(input, "\n")
    constructors = Dict()
    for line in lines
        line_parts = split(line, ",")
        name_constr = line_parts[1][end]
        arguments = replace(line_parts[end], "constants: {Dimensionality:" => "", "Constants:[" => "", "]}" => "")
        arguments = split(strip(arguments, ' '), " ")
        constructors[name_constr] = arguments
    end

    return constructors    
end


function parse_smt_output(smt_answer)
    found_values = Dict{}()
    if startswith(smt_answer, "sat")
        lines = eachmatch(r"(\w+\d+)*\s*\(\)\s*Int\s+\d+", smt_answer)
        for pattern in lines
            splited_pattern = split(pattern.match, " ")
            variable = splited_pattern[1]
            value = splited_pattern[end]
            found_values[variable] = value
        end  

        return true, found_values
    end

    return false, found_values
end


function substitute_coefs(expressions::Vector{Vector{Dict{String, Any}}}, replacements)
    simplified_expr = expressions
    for i in 1:length(expressions)
        for j in 1:2
            for (var, coef) in expressions[i][j]
                new_coef = coef
                name_coefs = eachmatch(r"\w\_\d*", new_coef)
                for m in name_coefs
                    new_coef = replace(new_coef, m.match => replacements[m.match])
                end
                simplified_expr[i][j][var] = new_coef |> Meta.parse |> eval |> Symbolics.simplify
            end
        end
    end
    return simplified_expr
end


function substitute_coefs(expressions::Dict, replacements)
    simplified_expr = expressions
    for (name, attr) in expressions
        for i in 1:length(attr)
            new_coef = attr[i]
            name_coefs = eachmatch(r"\w\_\d*", new_coef)
            for m in name_coefs
                new_coef = replace(new_coef, m.match => replacements[m.match])
            end
            simplified_expr[name][i] = new_coef
        end
    end
    return simplified_expr
end


function parse_output(output)
    needed_part = strip(split(output, "constructor and constants:")[end], [' ', '\n'])
    interpret_constr = strip(split(needed_part, "variables:")[1], [' ', '\n'])
    needed_part = strip(split(needed_part, "after similar ones:")[end], [' ', '\n'])
    expr_and_smtout = split(needed_part, "Результат выполнения команды:")
    exprs = strip(expr_and_smtout[1], [' ', '\n'])
    smtout = strip(expr_and_smtout[end], [' ', '\n'])
   
    linear_interpret = parse_expr(exprs)
    is_sat, vars_values = parse_smt_output(smtout)
    constructors = parse_interpretations(interpret_constr)
    
    if is_sat
        linear_interpret = substitute_coefs(linear_interpret, vars_values)
        constructors =  substitute_coefs(constructors, vars_values)       
    end
    
    return is_sat, constructors, linear_interpret
end

function add_monom(result_string_part, var, coef)
    if result_string_part == ""
        result_string_part  *= "$coef" * ((var == "") ? "" : " * " * var)
    else
        result_string_part  *= " + " * "$coef" * ((var == "") ? "" : " * " * var)
    end
    return result_string_part
end


function interpret_to_string(vector_interpret)
    result_string = ""
    for rule in vector_interpret
        result_string_left = ""
        result_string_right = ""
        for (var, coef) in rule[1]
            result_string_left = add_monom(result_string_left, var, coef)
        end
        for (var, coef) in rule[end]
            result_string_right = add_monom(result_string_right, var, coef)
        end

        result_string_left = result_string_left == "" ? "0" : result_string_left
        result_string_right = result_string_right == "" ? "0" : result_string_right

        result_string *= result_string_left * " > " * result_string_right * "\n"
    end
    
    return result_string
end

function construct_to_string(dict_constr)
    result_string = ""
    for (name, attr) in dict_constr
        result_string *= name * "("
        count_vars = parse(Int, attr[1])
        variables = join(["x$i" for i in 1:count_vars], ", ")
        result_string *= variables * ") = "

        right_part = ""
        for i in length(attr):-1:2
            if i == 2
                right_part = add_monom(right_part, "", attr[i])
            else
                right_part = add_monom(right_part, "x"*"$(i-2)", attr[i])
            end
        end
        result_string *= right_part * "\n"
    end
    
    return strip(result_string, '\n')
end


function write_trs_and_run_lab(trs_vector_of_strings, name_folder, name_file=name_folder)
    trs_string = join(trs_vector_of_strings, "\n")

    open("fileRead.txt", "w") do wtf 
        write(wtf, trs_string) 
    end
    output = interact_with_program(build_or_not(name_folder, name_file))
    
    is_sat, constructors, expr = parse_output(output)
    if is_sat
        println("Есть линейная интерпретация, показывающая завершаемость TRS")
        println(construct_to_string(constructors))
        println("Интерпретации после подстановки:")
        println(strip(interpret_to_string(expr), '\n'))
    else
        println("Линейными интерпретациями не удается доказать завершаемость TRS")
    end
    return is_sat, constructors, expr
end

end
