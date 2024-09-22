using JSON
include(joinpath(@__DIR__,"interpretation.jl"))
include(joinpath(@__DIR__,"structures.jl"))
include(joinpath(@__DIR__,"parsing_terms.jl"))
include(joinpath(@__DIR__,"json_and_interpret_hardcode.jl"))

parse_and_interpret(json_string_first)
parse_and_interpret(json_string_second)
