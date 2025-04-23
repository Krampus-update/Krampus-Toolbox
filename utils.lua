local utils = {}

function utils.atualizarAvatarPorMensagem(msg, mainPG)
    local avatarUrl
    if string.find(msg.content, "%f[%w]começa a ficar maior%f[%W]") then
        avatarUrl = "https://i.imgur.com/S7vCBeo.png"
    elseif string.find(msg.content, "%f[%w]começa a ficar menor%f[%W]") then
        avatarUrl = "https://th.bing.com/th/id/R.b56cb3f7dd1cdb7e1a097803ba1aced0?rik=zX6I1UCXrJJ8BA&pid=ImgRaw&r=0"
    end

    if avatarUrl then
        mainPG:asyncUpdate({ avatar = avatarUrl }):await()
    end
end

function utils.contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

function utils.processMessage(msg, validDataTypes)
        local objMesa = msg.room
    if objMesa == nil then
        return nil, nil, nil
    else
        local meuJogador = objMesa.me
        local mainPG = objMesa:findBibliotecaItem(meuJogador.personagemPrincipal)
        if mainPG == nil then
            return nil, nil, nil
        else
            local promise = mainPG:asyncOpenNDB()
            local sheet = await(promise)
            if utils.contains(validDataTypes, mainPG.dataType) then
                return mainPG, meuJogador, sheet
            else
                return nil, nil, nil
            end
        end
    end
end

return utils