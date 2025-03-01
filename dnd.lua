require("firecast.lua");
require("dialogs.lua");
require("scene.lua");

-- sempre que alguma mensagem é enviada no chat 
Firecast.listen("ChatMessage", function(msg)
    -- se a sala não for uma mesa (no caso ser um pv)
    local objMesa = msg.room;
    if objMesa == nil then
        return
    else
        -- salva meu Jogador e meu personagem principal
        local meuJogador = objMesa.me;
        local mainPG = objMesa:findBibliotecaItem(meuJogador.personagemPrincipal);
        -- se eu não tiver personagem principal cancela
        if mainPG == nil then
            return
        else
            -- salva a ficha do meu personagem principal na variavel sheet
            local promise = mainPG:asyncOpenNDB();
            local sheet = await(promise)
            -- detecta o sistema na qual o plugin está, no caso D&D
            if mainPG.dataType == "br.com.rrpg.DnD5_S3" then
                -- salva em uma variavel a vida atual e maxima
                local PV, PVMax = meuJogador:getBarValue(1);
                local PVTemp = meuJogador:getBarValue(2);
                -- define a vida maxima e atual da ficha pra ser igual a vida maxima e atual da barrinha
                sheet.PV = PV;
                sheet.PVMax = PVMax;
                sheet.PVTemporario = PVTemp;
                -- define a seguinda linha para conter a CA, PP e CD (de magia) do personagem atual
                meuJogador:requestSetEditableLine(2,
                    "CA " .. (sheet.CA or  0) .. " | PP " .. (sheet.sabedoriaPassiva or 0) .. " | CD " .. (sheet.magias.cdDaMagia or 0));
                -- se for o Nair (meu personagem)
                if sheet.nome == "[§K3]N[§K18]a[§K1]ir" then
                    -- faz um calculo doido para calcular a altura dele com base na vida atual dele
                    local alturaMin = 1.2;
                    local alturaMax = 2.4;

                    local alturaAtual = math.floor((alturaMin + (PV / PVMax) * (alturaMax - alturaMin)) * 100) / 100;
                    -- muda a primeira linha para ter a classe e a altura calculada
                    meuJogador:requestSetEditableLine(1, sheet.classeENivel .. " | " .. alturaAtual .. "m");
                else
                    -- se não for o Nair só irá salvar a classe e nivel na primeira linha
                    meuJogador:requestSetEditableLine(1, sheet.classeENivel);
                end
                -- essa parte registra o plugin no scene para que eu possa atualizar as barras de vida do token no qual meu personagem seja dono
                SceneLib.registerPlugin(function(scene, attachment)
                    -- verifica todos os items no scene
                    for i = 1, #scene.items, 1 do
                        -- se o item verificado for um token
                        if scene.items[i].objectType == "token" then
                            -- se o token verificado tiver o mesmo id do meu(pessoa usando o plugin)
                            if scene.items[i].ownerCharacter == meuJogador.personagemPrincipal then
                                -- então ele define a vida maxima e a atual do token pra ser igual a vida maxima e atual da barrinha
                                scene.items[i].barMax1 = PVMax;
                                scene.items[i].barValue1 = PV;
                            end
                        end
                    end
                end);
            end
        end
    end
end)
