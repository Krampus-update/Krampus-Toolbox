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
        end
    end)
end

if toolbox.think == nil or toolbox.think == "" then
    toolbox.think = true
end

Firecast.listen("HandleChatCommand", function(message)
    -- verifica se a mensagem é o comando "/toggle"
    if message.command == "toggle" then
        message.response = {handled=true};
        -- se o bot estiver ativado ele desativa e vice-versa
        if toolbox.activated then
            toolbox.activated = false
            message.chat:asyncSendStd("Desativado.", {
                talemarkOptions = {
                    defaultTextStyle = {
                        color = "DarkOrange",
                        underline = true
                    }
                }
            }).await()
        else
            toolbox.activated = true
            message.chat:asyncSendStd("Ativado.", {
                talemarkOptions = {
                    defaultTextStyle = {
                        color = "DarkOrange",
                        underline = true
                    }
                }
            }).await()
        end
    end

    -- verifica se a mensagem é o comando "/think"
    if message.command == "think" then
        -- se o bot estiver ativado ele desativa e vice-versa
        message.response = {handled=true};
        if toolbox.think then
            toolbox.think = false
            message.chat:asyncSendStd("Pensamento Desativado.", {
                talemarkOptions = {
                    defaultTextStyle = {
                        color = "DarkOrange",
                        underline = true
                    }
                }
            }).await()
        else
            toolbox.think = true
            message.chat:asyncSendStd("Pensamento Ativado.", {
                talemarkOptions = {
                    defaultTextStyle = {
                        color = "DarkOrange",
                        underline = true
                    }
                }
            }).await()
        end
    end

    -- verifica se a mensagem é o comando "/model"
    if message.command == "model" then
        message.response = {handled=true};
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
    -- verifica se a mensagem é o comando "/endpoint"
    if message.command == "endpoint" then
        message.response = {handled=true};
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
    -- verifica se a mensagem é o comando "/key"
    if message.command == "key" then
        message.response = {handled=true};
        Dialogs.inputQuery("API Key", "Insira a chave da API:", toolbox.apiKey, function(userInput)
            -- se a chave não for nula ou vazia salva na DB
            if userInput ~= nil and userInput ~= "" then
                toolbox.apiKey = userInput
                return
            end
        end)
    end

    if message.command == "ai" then
        -- se o bot estiver desativado ele não faz nada
        message.response = {handled=true};
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
                response = response:gsub("â€“", "–")
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
                response = response:gsub("Ã“", "Ó")

                -- arrumando o espaço para pensamento
                local think = response:match('<think>(.-)</think>')
                response = response:gsub("<think>(.-)</think>", "")
                -- se a sala existir
                if message.room == nil then
                    -- se o chat for privado
                    message.chat:escrever("ERROR: Não é possível enviar mensagens privadas.")
                    return
                else
                    if toolbox.think then
                        local chat = await(message.room:asyncOpenPVT(message.player.login, {
                            autofocus = false
                        }))
                        -- se o pensamento estiver ativado ele envia a mensagem de pensamento
                        chat:asyncSendStd(think, {
                            talemarkOptions = {
                                defaultTextStyle = {
                                    color = "#0f0f0f"
                                },
                                parseCharActions = false,
                                parseCharEmDashSpeech = false,
                                parseCharQuotedSpeech = false,
                                parseSmileys = false
                            }
                        }).await()
                    end
                    message.chat:asyncSendStd(response, {
                        talemarkOptions = {
                            defaultTextStyle = {
                                color = "#f0f0f0"
                            },
                            parseCharActions = false,
                            parseCharEmDashSpeech = false,
                            parseCharQuotedSpeech = false,
                            parseSmileys = false
                        }
                    }).await()
                end
            end
            request.onError = function(errormessage)
                message.chat:escrever("ERROR: " .. errormessage)
            end

            if message.parameter ~= nil or message.parameter == "" then
                request:send('{"model": "' .. toolbox.model ..
                                 ':online", "messages":[{"role": "system","content":"you are an assistant for a VTT program called firecast, you will receive messages in portuguese most of the time so try to keep your responses concise and relevant. Dont use emotes only plain text and markdown compatible things"},{"role": "user","content": "following your guidelines answer the following prompt as close as you can, try to be productive and suggest changes (if needed). Prompt: ' ..
                                 message.parameter .. '"}], "temperature": 0.7, "max_tokens": 10000,"stream":false}')
            end
        end
    end
end)

Firecast.listen("ListChatCommands", function(message)
    message.response = {{command = "[§K9]ai <Pergunta>", description = "[§K9]Faz uma pergunta para a IA."},
                        {command = "[§K9]toggle", description = "[§K9]Ativa ou desativa o bot."},
                        {command = "[§K9]think", description = "[§K9]Ativa ou desativa o pensamento."},
                        {command = "[§K4]model", description = "[§K4]Muda o modelo da IA."},
                        {command = "[§K4]endpoint", description = "[§K4]Muda o endpoint da IA."},
                        {command = "[§K4]key", description = "[§K4]Muda a chave da API."}}
end)