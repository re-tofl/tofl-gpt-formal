function reply(type, args...) 
    push!(Main.reply_to_chat, Dict("format"=>type, "data"=>join(args, "\n")*"\n"))
end
function code_reply(args...) 
    reply("code", args) 
end
function text_reply(args...) 
    reply("text", args)
end
