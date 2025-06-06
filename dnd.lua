require("firecast.lua");
require("dialogs.lua");
require("scene.lua");
local utils = require("utils.lua");

local validDataTypes = {"br.com.rrpg.DnD5_S3", "MultiVerso_MdB_Shinobi"}

Firecast.listen("ChatMessage", function(msg)
    local mainPG, meuJogador, sheet = utils.processMessage(msg, validDataTypes)
    if mainPG == nil then
        return
    end
    sheet.PV = mainPG.bar0Val
    sheet.PVMax = mainPG.bar0Max
    sheet.PVTemporario = mainPG.bar1Val
    sheet.dadosdevidatotal = mainPG.bar2Max

    if sheet.nome == "[§K3]N[§K18]a[§K1]ir" then
        utils.atualizarAvatarPorMensagem(msg, mainPG)
        local alturaMin = 1.2;
        local alturaMax = 2.4;
        local alturaAtual = math.floor((alturaMin + (tonumber(sheet.PV) / tonumber(sheet.PVMax)) *
                                           (alturaMax - alturaMin)) * 100) / 100;
        mainPG:asyncUpdate({
            edtLine0 = sheet.classeENivel .. " | " .. alturaAtual .. "m",
            edtLine1="CA " .. (sheet.CA or 0) .. " | PP " .. (sheet.sabedoriaPassiva or 0) .. " | CD " .. (sheet.magias.cdDaMagia or 0)
        }):await()
    else
        mainPG:asyncUpdate({
            edtLine0 = sheet.classeENivel,
            edtLine1="CA " .. (sheet.CA or 0) .. " | PP " .. (sheet.sabedoriaPassiva or 0) .. " | CD " .. (sheet.magias.cdDaMagia or 0)
        }):await()
    end
    SceneLib.registerPlugin(function(scene, attachment)
        for i = 1, #scene.items, 1 do
            if scene.items[i].objectType == "token" and scene.items[i].ownerCharacter == meuJogador.personagemPrincipal then
                scene.items[i].barValue1 = tonumber(sheet.PV);
                scene.items[i].barMax1 = tonumber(sheet.PVMax);
            end
        end
    end);
end)
