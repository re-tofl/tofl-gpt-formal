function reply(type, arg) 
    push!(Main.reply_to_chat["result"], Dict("format"=>type, "data"=>arg))
end

function code_reply(arg) 
    reply("code", arg) 
end

function text_reply(arg) 
    reply("text", arg)
end
