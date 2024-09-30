using Base.Sys


function build_or_not(folder_name::String, target_file::String)

    current_dir = pwd()
    dirs_to_check = [current_dir, dirname(current_dir)]
    folder_path = ""

    for dir in dirs_to_check
        if isdir(joinpath(dir, folder_name))
            folder_path = joinpath(dir, folder_name)
        end
    end

    file_path = joinpath(folder_path, target_file)
    println("Ищем '$file_path'")

    # Проверяем наличие искомого исполняемого файла
    if !(isfile(file_path) && isexecutable(file_path))
        println("Файл '$target_file' не найден. Выполняем команду 'go build .'")
        cd(folder_path) do
            read(run(`go build .`), )
        end
    end

    return "$file_path"
end


function interact_with_program(path::String)
    #io = open(pipeline(`$path`, stdout=stdout, stderr=stderr), "w+")

    io = open(`$path`; write=true, read=true)
    write(io, "2\n")
    output = read(io, String)

    open(path*"_output.txt", "w") do wtf 
        write(wtf, output) 
    end

    close(io)
end


function parse_map(input::String)
    cleaned_string = replace(input, "map[" => "")[1:end-1]
    result_dict = Dict{String, String}()

    # Разбиение по пробелам
    pairs = split(cleaned_string, r"\s+(?=\w+:)")
    
    for pair in pairs
        # Разделение ключа и значения по двоеточию
        key_value = split(pair, ":")
        println(key_value)
        
        if length(key_value) == 2
            key = strip(key_value[1])
            value = strip(replace(key_value[2], r"^\[\s*" => "", r"\s*\]$" => ""))
            result_dict[key] = valuе
        end
    end

    return result_dict    
end


function parse_expr(input::String)
    sections = split(input, "\n")
    num_sections = length(sections)
    
    all_expr = Vector{Vector{Dict{String, Any}}}(undef, div(num_sections, 3))

    index = 0
    for section in sections
        if startswith(section, r"\d+")
            index += 1
            v = [Dict{String, Any}(), Dict{String, Any}()]
            all_expr[index] = v
        elseif startswith(section, "left")
            dict = parse_map(section[6:end])
            all_expr[index][1] = dict
        elseif startswith(section, "right")
            dict = parse_map(section[7:end])
            all_expr[index][2] = dict
        else 
            println("что-то не так", section, " xclksnlk")
        end
    end
    return all_expr
end

function parse_smt_output()
    #здесь будет парсинг для извлечения значений коэффициентов
end


function parse_output(output::String)
    #здесь будет парсинг всего вывода программы
end


input_string = """0:
left: map[ :[s_0 * f_1 + f_0] x:[f_2] y:[s_1 * f_1]]
right: map[ :[f_0 * s_1 + s_0] x:[f_2 * s_1] y:[f_1 * s_1]]
1:
left: map[ :[f_0] x:[f_2] z:[f_1]]
right: map[ :[h_0] x:[h_1]]"""


#println(parse_expr(input_string))
#interact_with_program(build_or_not("lab1", "lab1.exe"))
