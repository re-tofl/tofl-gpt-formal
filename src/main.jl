using JSON
using Symbolics
include("server.jl")
# Формат ответа в чат
# {
#     "result": [
#         {"format": "code", "data": "..."},
#         {"format": "text", "data": "..."}
#     ]
# }

port = 8081
@async begin
    HTTP.serve(request_handler, "0.0.0.0", port)
end

while true
    sleep(1)
end

