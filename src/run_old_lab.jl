using Base.Sys
using Symbolics


function build_or_not(folder_name, name_file)
    current_dir = pwd()
    dirs_to_check = [current_dir, dirname(current_dir)]
    folder_path = ""

    for dir in dirs_to_check
        if isdir(joinpath(dir, folder_name))
            folder_path = joinpath(dir, folder_name)
        end
    end

    postfixes = ["", ".exe"]
    is_found = false
    file_path = ""
    for postfix in postfixes
        target_file = name_file * postfix
        file_path = joinpath(folder_path, target_file)
        # Проверяем наличие искомого исполняемого файла
        if (isfile(file_path) && isexecutable(file_path))
            is_found = true
            @info "Будет использован '$file_path'"
        end
    end

    if !(is_found)
        @info "Файл '$name_file' не найден. Выполняем команду 'go build .'"
        cd(folder_path) do
            read(run(`go build .`), )
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

function parse_smt_output(smt_answer)
    found_values = Dict{}()
    if startswith(smt_answer, "sat")
        lines = eachmatch(r"\w+\d+\s*\(\)\s*Int\s+\d+", smt_answer)
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

function substitute_coefs(expressions, replacements)
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

function parse_output(output)
    needed_part = strip(split(output, "after similar ones:")[end], [' ', '\n'])
    expr_and_smtout = split(needed_part, "Результат выполнения команды:")
    exprs = strip(expr_and_smtout[1], [' ', '\n'])
    smtout = strip(expr_and_smtout[end], [' ', '\n'])
   
    linear_interpret = parse_expr(exprs)
    is_sat, vars_values = parse_smt_output(smtout)
    
    if is_sat
        linear_interpret = substitute_coefs(linear_interpret, vars_values)        
    end
    
    return is_sat, linear_interpret
end

#trs_rules=nothing будет убрано, когда определим формат этой переменной
function write_trs_and_run_lab(name_folder, name_file=name_folder, trs_rules=nothing)
    # здесь будем конвертировать формат входа в строку для записи в файл
    # нужно будет определить формат для trs_rules
    """
    trs_string = tostring(trs_rules)

    open("fileRead.txt", "w") do wtf 
        write(wtf, trs_string) 
    end
    """
    output = interact_with_program(build_or_not(name_folder, name_file))
    
    is_sat, expr = parse_output(output)
    @info "В стадии разработки. Для данных из файла is_sat = '$is_sat'"
    return parse_output(output)
end

#println(write_trs_and_run_lab("lab1"))
