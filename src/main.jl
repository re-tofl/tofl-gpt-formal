using JSON
using Symbolics
include(joinpath(@__DIR__,"structures.jl"))
include(joinpath(@__DIR__,"jsons_data.jl"))
include(joinpath(@__DIR__,"parse_interpretations.jl"))
include(joinpath(@__DIR__,"parse_TRS_and_apply_interpretations.jl"))
include(joinpath(@__DIR__,"display_interpretations.jl"))
# Выводим интерпретации
display_interpretations()

interpretations = Dict{String, Function}()

parse_and_interpret(json_string_first, interpretations)
parse_and_interpret(json_string_second, interpretations)
