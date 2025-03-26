require("firecast.lua");
require("dialogs.lua");
require("scene.lua");
local utils = require("utils.lua");

local validDataTypes = {"br.com.rrpg.DnD5_S3"}

Firecast.listen("ChatMessage", function(msg)
    local mainPG, meuJogador, sheet = utils.processMessage(msg,validDataTypes)
    if mainPG == nil then
        return
    end

    sheet.PV, sheet.PVMax = meuJogador:getBarValue(1);
    sheet.PVTemporario = meuJogador:getBarValue(2);
    meuJogador:requestSetEditableLine(2, "CA " .. (sheet.CA or 0) .. " | PP " ..
        (sheet.sabedoriaPassiva or 0) .. " | CD " .. (sheet.magias.cdDaMagia or 0));
    if sheet.nome == "[§K3]N[§K18]a[§K1]ir" then
        local alturaMin = 1.2;
        local alturaMax = 2.4;
        local alturaAtual = math.floor((alturaMin + (tonumber(sheet.PV) / tonumber(sheet.PVMax)) * (alturaMax - alturaMin)) * 100) / 100;
        meuJogador:requestSetEditableLine(1, sheet.classeENivel .. " | " .. alturaAtual .. "m");
    else
        meuJogador:requestSetEditableLine(1, sheet.classeENivel);
    end
    SceneLib.registerPlugin(function(scene, attachment)
        for i = 1, #scene.items, 1 do
            if scene.items[i].objectType == "token" then
                if scene.items[i].ownerCharacter == meuJogador.personagemPrincipal then
                    scene.items[i].barMax1 = tonumber(sheet.PVMax);
                end
            end
        end
    end);
end)
