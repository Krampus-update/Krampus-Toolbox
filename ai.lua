require("ndb")
require("dialogs.lua")
require("internet.lua")
require("firecast.lua")

-- acessando ou criando a DB
local toolbox = NDB.load("toolbox.xml")

-- verifica se a DB tem algo se não cria uma tabela vazia
if toolbox == nil then
    toolbox = {}
end

-- verifica qual o estado do bot
if toolbox.activated == nil then
    toolbox.activated = false
end

-- verifica se a chave da API está vazia ou nula
while toolbox.apiKey == nil or toolbox.apiKey == "" do
    -- se estiver vazia ou nula pede a chave da API
    Dialogs.inputQuery("API Key", "Insira a chave da API:", "", function(userInput)
        -- se a chave não for nula ou vazia salva na DB
        if userInput ~= nil and userInput ~= "" then
            toolbox.apiKey = userInput
        else
            Dialogs.showMessage("Chave da API não pode ser vazia.")
        end
    end)
end

-- verifica se o endpoint está vazio ou nulo
if toolbox.endpoint == nil or toolbox.endpoint == "" then
    -- se estiver vazio ou nulo pede o endpoint
    Dialogs.inputQuery("Endpoint", "Insira o endpoint:", "https://openrouter.ai/api/v1/chat/completions",
        function(userInput)
            -- se o endpoint não for nulo ou vazio salva na DB
            if userInput ~= nil and userInput ~= "" then
                toolbox.endpoint = userInput
            else
                toolbox.endpoint = "https://openrouter.ai/api/v1/chat/completions"
            end
        end)
end

-- verifica se o modelo está vazio ou nulo
if toolbox.model == nil or toolbox.model == "" then
    -- se estiver vazio ou nulo pede o modelo
    Dialogs.inputQuery("Modelo", "Insira o modelo:", "deepseek/deepseek-r1:free", function(userInput)
        -- se o modelo não for nulo ou vazio salva na DB
        if userInput ~= nil and userInput ~= "" then
            toolbox.model = userInput
        else
            -- se o modelo for nulo ou vazio salva o modelo padrão
            toolbox.model = "deepseek/deepseek-r1:free"
        end
    end)
end

Firecast.listen("ChatMessage", function(msg)
    -- verifica se a mensagem é minha 
    if msg.mine then
        -- verifica se a mensagem é o comando "!key"
        if msg.content == "!key" then
            Dialogs.inputQuery("API Key", "Insira a chave da API:", toolbox.apiKey, function(userInput)
                -- se a chave não for nula ou vazia salva na DB
                if userInput ~= nil and userInput ~= "" then
                    toolbox.apiKey = userInput
                    return
                end
            end)
        end
        -- verifica se a mensagem é o comando "!endpoint"
        if msg.content == "!toggle" then
            -- se o bot estiver ativado ele desativa e vice-versa
            if toolbox.activated then
                toolbox.activated = false
                msg.chat:enviarMensagem("Desativado.")
            else
                toolbox.activated = true
                msg.chat:enviarMensagem("Ativado.")
            end
        end
        -- verifica se a mensagem é o comando "!model"
        if msg.content == "!model" then

            Dialogs.inputQuery("Modelo", "Insira o modelo:", toolbox.model, function(userInput)
                -- se o modelo não for nulo ou vazio salva na DB
                if userInput ~= nil and userInput ~= "" then
                    toolbox.model = userInput
                    return
                else
                    -- se o modelo for nulo ou vazio mantem o atual
                    toolbox.model = toolbox.model
                end
            end)
        end
        -- verifica se a mensagem é o comando "!endpoint"
        if msg.content == "!endpoint" then
            Dialogs.inputQuery("Endpoint", "Insira o endpoint:", toolbox.endpoint, function(userInput)
                -- se o endpoint não for nulo ou vazio salva na DB
                if userInput ~= nil and userInput ~= "" then
                    toolbox.endpoint = userInput
                    return
                else
                    -- se o endpoint for nulo ou vazio mantem o atual
                    toolbox.endpoint = toolbox.endpoint
                end
            end)
        end
    end

    -- verifica se o bot esta desativa
    if not toolbox.activated then
        return
    else
        -- se não estiver desativado ele faz um request para a API
        local request = Internet.newHTTPRequest("POST", toolbox.endpoint)
        -- adicionando os headers
        request:setRequestHeader("Authorization", "Bearer " .. toolbox.apiKey)
        request:setRequestHeader("Content-Type", "application/json")
        -- definindo o que fazer quando receber a resposta
        request.onResponse = function()
            local response = request.responseText
            response = response:match('"content":"(.-)","')
            -- arrumando os caracteres especiais
            response = response:gsub("\"", "'")
            response = response:gsub("\\n", "\n")
            response = response:gsub("â€“", "’")
            response = response:gsub("Ã§", "ç")
            response = response:gsub("Ã£", "ã")
            response = response:gsub("Ã©", "é")
            response = response:gsub("Ã´", "ô")
            response = response:gsub("Ãº", "ú")
            response = response:gsub("â€™", "’")
            response = response:gsub("Ãª", "ê")
            response = response:gsub("Ã¡", "á")
            response = response:gsub("Ã³", "ó")
            response = response:gsub("Ã‰", "É")
            response = response:gsub("â€”", "—")
            response = response:gsub("Ãµ", "õ")
            response = response:gsub("Ã ", "à")
            response = response:gsub("Ã¢", "â")
            response = response:gsub("â‰¥", "≥")
            response = response:gsub("Ã­", "í")

            -- arrumando o espaço para pensamento
            local think = response:match('<think>(.-)</think>')
            response = response:gsub("<think>(.-)</think>", "")
            -- se a sala existir
            if msg.room == nil then
                -- se o chat for privado
                msg.chat:escrever("ERROR: Não é possível enviar mensagens privadas.")
                return
            else
                local chat = await(msg.room:asyncOpenPVT(msg.player.login, {
                    autofocus = false
                }))
                chat:enviarMensagem(think)
                msg.chat:enviarMensagem(response)
            end
        end
        request.onError = function(errorMsg)
            msg.chat:escrever("ERROR: " .. errorMsg)
        end

        if msg.type == "action" then
            request:send('{"model": "' .. toolbox.model ..
                             '", "messages":[{"role": "system","content":"you are an assistant for a VTT program, you will receive messages in portuguese most of the time so try to keep your responses concise and relevant. dont use emotes only plain text and markdown compatible things"},{"role": "user","content": "following your guidelines answer the following prompt as close as you can, try to be productive and suggest changes (if needed). Prompt: ' ..
                             msg.content .. '"}], "temperature": 0.7, "max_tokens": 5000,"stream":false}')
        end
    end
end)
