local teste = NDB.getChildNodes(sheet.txt)
for i = 1, #teste, 1 do
    showMessage(Utils.tableToStr(teste[i],true))
end