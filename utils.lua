local utils = {}

function utils.contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

function utils.processMessage(msg,validDataTypes)
    
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