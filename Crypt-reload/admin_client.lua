
addEvent( 'Crypt:onGetPermissions', true )
addEvent( 'Crypt:onGetResourceList', true )
addEvent( 'Crypt:onGetResourceFiles', true )
addEvent( 'Crypt:onActionError', true )
addEvent( 'Crypt:onInfo', true )

local ACTIONS_ERROR_CODES = {
	[1] = 'У вас нет прав на старт ресурса.';
	[2] = 'Crypt не имеет прав на старт ресурса.\nНеобходимо право "function.startResource"';
	[3] = 'Ресурс &1 не найден.';
	[4] = 'Не удалось запустить ресурс.';
	[5] = 'У вас нет прав на остановку ресурса.';
	[6] = 'Crypt не имеет прав на остановку ресурса.\nНеобходимо право "function.stopResource"';
	[7] = 'Не удалось остановить ресурс.';
	[8] = 'Неверный аргумент obfuscate';
	[9] = 'Неверный аргумент scripts';
	[10] = 'Резервная копия не была создана\nВероятно, нет места на диске или имя файла велико.';
	[11] = 'У вас нет прав command.refreshall.';
	[12] = 'У вас нет прав command.refresh.';
	[13] = 'Неверный аргумент compile.';
	[14] = 'Неверный аргумент stripDebug.';
	[15] = 'Ресурс запущеню';
	[16] = 'Не верный аргумент files.';
	[17] = 'Указан несуществующий метод шифрования.';
	[18] = 'У вас нет прав на шифрование файлов.\nТребуется право "function.cryptres"';
}

local REQUEST_PERMISSIONS = {
	[1] = 'general.ModifyOtherObjects';
	[2] = 'function.fetchRemote';
	[3] = 'function.startResource';
	[4] = 'function.stopResource';
	[5] = 'function.refreshResources';
}

function GuiWindow:center( )
	local sX, sY = guiGetScreenSize()
	local w,h = self:getSize( false )
	return self:setPosition( ( sX - w ) / 2, ( sY - h ) / 2, false )
end

--------------------------
--   Список ресурсов    --
--------------------------

local resourcesList = {}
local mainWindow, resourcesGridList, searchEdit

local function generateResourcesGridList()
	local filter = searchEdit:getText()
	resourcesGridList:clear()
	if filter == '' then
		for i = 1, #resourcesList do
			local row = resourcesGridList:addRow( )
			local resourceInfo = resourcesList[i]
			resourcesGridList:setItemText ( row, 1, resourceInfo[1], false, false )
			resourcesGridList:setItemText ( row, 2, resourceInfo[2] or resourceInfo[1], false, false )
			resourcesGridList:setItemText ( row, 3, resourceInfo[3], false, false )
		end
	else
		for i = 1, #resourcesList do
			local resourceInfo = resourcesList[i]
			if resourceInfo[1]:lower( ):find( filter ) or resourceInfo[2] and resourceInfo[2]:lower( ):find( filter ) then
				local row = resourcesGridList:addRow( )
				resourcesGridList:setItemText ( row, 1, resourceInfo[1], false, false )
				resourcesGridList:setItemText ( row, 2, resourceInfo[2] or resourceInfo[1], false, false )
				resourcesGridList:setItemText ( row, 3, resourceInfo[3], false, false )
			end
		end	
	end
end

local function getSelectedResourceName()
	local resourceName =  resourcesGridList:getItemText( resourcesGridList:getSelectedItem( ), 1 )
	return resourceName ~= '' and resourceName
end

local function createMainWindow( )
	if mainWindow then
		return mainWindow
	end
	mainWindow = GuiWindow( 0, 0, 600, 300, 'Список ресурсов', false )
	mainWindow:center()
	mainWindow:setSizable( false )

	GuiLabel( 15, 25, 90, 20, 'Поиск ресурса:', false, mainWindow )
	searchEdit = GuiEdit( 105, 25, 305, 20, '', false, mainWindow )

	resourcesGridList = GuiGridList( 10, 50, 400, 280, false, mainWindow )
	--gridList:setSelectionMode( 1 )
	resourcesGridList:addColumn( 'Ресурс', 0.40 )
	resourcesGridList:addColumn( 'Имя', 0.35 )
	resourcesGridList:addColumn( 'Состояние', 0.15 )

	local resourceMenuButton = GuiButton( 420, 25, 180, 20, 'Меню ресурса', false, mainWindow )
	local startResourceButton = GuiButton( 420, 50, 180, 20, 'Старт ресурса', false, mainWindow )
	local stopResourceButton = GuiButton( 420, 75, 180, 20, 'Стоп ресурса', false, mainWindow )

	local updateListButton = GuiButton( 420, 125, 180, 20, 'Обновить список', false, mainWindow )
	local refreshButton = GuiButton( 420, 150, 180, 20, 'Refresh', false, mainWindow )
	local refreshAllButton = GuiButton( 420, 175, 180, 20, 'Refresh all', false, mainWindow )

	local closeButton = GuiButton( 420, 270, 180, 20, 'Выход', false, mainWindow )

	showCursor( true )

	guiSetInputMode( 'no_binds_when_editing' )

	addEventHandler( 'onClientGUIClick', searchEdit, function()
		searchEdit:setText( '' )
		generateResourcesGridList()
	end, false )

	addEventHandler( 'onClientGUIChanged', searchEdit, function( )
		generateResourcesGridList()
	end, false )

	addEventHandler( 'onClientGUIClick', resourceMenuButton, function()
		local resourceName = getSelectedResourceName()
		if resourceName then
			mainWindow:setVisible( false )
			createResourceWindow( resourceName )
		end
	end, false )

	addEventHandler( 'onClientGUIClick', startResourceButton, function()
		local resourceName = getSelectedResourceName()
		if resourceName then
			triggerServerEvent( 'Crypt:requestAction', root, 'startResource', resourceName )
		end
	end, false )

	addEventHandler( 'onClientGUIClick', stopResourceButton, function()
		local resourceName = getSelectedResourceName()
		if resourceName then
			triggerServerEvent( 'Crypt:requestAction', root, 'stopResource', resourceName )
		end
	end, false )

	addEventHandler( 'onClientGUIClick', updateListButton, function()
		triggerServerEvent( 'Crypt:requestAction', root, 'getResourcesList' )
	end, false )

	addEventHandler( 'onClientGUIClick', refreshButton, function()
		triggerServerEvent( 'Crypt:requestAction', root, 'refreshReources', false )
	end, false )

	addEventHandler( 'onClientGUIClick', refreshAllButton, function()
		triggerServerEvent( 'Crypt:requestAction', root, 'refreshReources', true )
	end, false )

	addEventHandler( 'onClientGUIClick', closeButton, function()
		mainWindow:destroy()
		mainWindow, resourcesGridList, searchEdit = nil, nil, nil
		showCursor( false )
	end, false )

	triggerServerEvent( 'Crypt:requestAction', root, 'getResourcesList' )

	return mainWindow
end

addEventHandler( 'Crypt:onGetResourceList', root, function( newResourceList )
	resourcesList = newResourceList
	if resourcesGridList then
		generateResourcesGridList()
	end
end )

-----------------------------
-- Окно настрооек шифровки --
-----------------------------

local scriptCompileWindow, encryptWindow

local function createCompileWindow( resourceName, scripts )
	scriptCompileWindow = GuiWindow( 0, 0, 300, 220, 'Компиляция скриптов', false )
	scriptCompileWindow:setSizable( false )

	scriptCompileWindow:center()

	GuiLabel( 15, 25, 270, 20, 'Шифровка скриптов (' .. #scripts .. ') ' .. resourceName, false, scriptCompileWindow  )

	local compileCheckBox = GuiCheckBox( 15, 50, 270, 20, 'Компиляция', true, false, scriptCompileWindow )
	local stripDebugInformationCheckBox = GuiCheckBox( 15, 75, 270, 20, 'Очистить информацию для дебага', true, false, scriptCompileWindow )
	local noObfuscateRadio = GuiRadioButton( 15, 100, 270, 20, 'Без обфускациции', false, scriptCompileWindow )
	local normalObfuscateCheckBox = GuiRadioButton( 15, 125, 270, 20, 'Обычная обфускациция', false, scriptCompileWindow )
	local maxObfuscateCheckBox = GuiRadioButton( 15, 150, 270, 20, 'Максимальная обфускациция', false, scriptCompileWindow )

	maxObfuscateCheckBox:setSelected( true )

	local doneButton = GuiButton( 40, 180, 100, 30, 'Поехали!', false, scriptCompileWindow )
	local closeButton = GuiButton( 160, 180, 100, 30, 'Отмена', false, scriptCompileWindow )

	addEventHandler( 'onClientGUIClick', doneButton, function()
		local compile = compileCheckBox:getSelected()
		local stripDebug = stripDebugInformationCheckBox:getSelected()
		local obfuscate
		if maxObfuscateCheckBox:getSelected() then
			obfuscate = 2
		elseif normalObfuscateCheckBox:getSelected() then
			obfuscate = 1
		else
			obfuscate = 0
		end
		triggerServerEvent( 'Crypt:requestAction', root, 'compileScripts', resourceName, scripts, compile, stripDebug, obfuscate )
		if encryptWindow then
			encryptWindow:setVisible( true )
		end
	end, false )

	addEventHandler( 'onClientGUIClick', closeButton, function()
		scriptCompileWindow:destroy()
		scriptCompileWindow = nil
		if encryptWindow then
			encryptWindow:setVisible( true )
		end
	end, false )

end

local function createFilesEncryptWindow( resourceName, files )
	encryptWindow = GuiWindow( 0, 0, 300, 150, 'Шифрование файлов', false )
	encryptWindow:setSizable( false )

	encryptWindow:center()

	GuiLabel( 15, 25, 270, 20, 'Шифрование файлов (' .. #files .. ') ' .. resourceName, false, encryptWindow )
	GuiLabel( 15, 50, 270, 20, 'Режим:', false, encryptWindow )
	local modeSelectCombo = GuiComboBox( 70, 50, 220, 110, 'Режим', false, encryptWindow )
	GuiLabel( 15, 75, 270, 20, 'Пароль:', false, encryptWindow )
	local passworldEdit = GuiEdit( 70, 75, 220, 20, '', false, encryptWindow )

	for modeName in pairs( cryptMethods ) do
		modeSelectCombo:addItem( modeName )
	end

	local doneButton = GuiButton( 40, 110, 100, 30, 'Зашифровать', false, encryptWindow )
	local closeButton = GuiButton( 160, 110, 100, 30, 'Отмена', false, encryptWindow )

	addEventHandler( 'onClientGUIClick', doneButton, function()
		local mode = modeSelectCombo:getItemText( modeSelectCombo:getSelected() )
		local passworld = passworldEdit:getText()
		triggerServerEvent( 'Crypt:requestAction', root, 'encryptFiles', resourceName, files, mode, passworld )
		encryptWindow:destroy()
		encryptWindow = nil
	end, false )

	addEventHandler( 'onClientGUIClick', closeButton, function()
		encryptWindow:destroy()
		encryptWindow = nil
	end, false )
end

local function createFilesDecryptWindow( resourceName, files )
	local decryptWindow = GuiWindow( 0, 0, 300, 125, 'Расшифровка файлов', false )
	decryptWindow:setSizable( false )

	decryptWindow:center()

	GuiLabel( 15, 25, 270, 20, 'Расшифровка файлов (' .. #files .. ') ' .. resourceName, false, decryptWindow )
	GuiLabel( 15, 50, 270, 20, 'Пароль:', false, decryptWindow )
	local passworldEdit = GuiEdit( 70, 50, 220, 20, '', false, decryptWindow )

	local doneButton = GuiButton( 40, 85, 100, 30, 'Расшифровать', false, decryptWindow )
	local closeButton = GuiButton( 160, 85, 100, 30, 'Отмена', false, decryptWindow )

	addEventHandler( 'onClientGUIClick', doneButton, function()
		local passworld = passworldEdit:getText()
		triggerServerEvent( 'Crypt:requestAction', root, 'decryptFiles', resourceName, files, passworld )
		decryptWindow:destroy()
	end, false )

	addEventHandler( 'onClientGUIClick', closeButton, function()
		decryptWindow:destroy()
	end, false )
end


--------------------------
--     Окно ресурса     --
--------------------------

function createResourceWindow( resourceName )
	local resourceWindow = GuiWindow( 0, 0, 600, 300, 'Ресурс: ' ..resourceName, false )
	resourceWindow:center()
	resourceWindow:setSizable( false )

	GuiLabel( 15, 25, 400, 20, 'Используй Ctrl и Shrift для множественного выделения', false, resourceWindow  )

	local metaGridList = GuiGridList( 10, 50, 400, 280, false, resourceWindow )

	metaGridList:addColumn( 'Тип', 0.12 )
	metaGridList:addColumn( 'Путь', 0.35 )
	metaGridList:addColumn( 'Сторона', 0.15 )
	metaGridList:addColumn( 'Кэш', 0.15 )
	metaGridList:addColumn( 'Шифровка', 0.13 )

	metaGridList:setSelectionMode( 1 )

	local startResourceButton = GuiButton( 420, 25, 180, 20, 'Старт ресурса', false, resourceWindow )
	local stopResourceButton = GuiButton( 420, 50, 180, 20, 'Стоп ресурса', false, resourceWindow )

	local encryptButton = GuiButton( 420, 75, 180, 20, 'Зашифровать', false, resourceWindow )
	local decryptButton = GuiButton( 420, 100, 180, 20, 'Расшифровать', false, resourceWindow )
	--local cacheButton = GuiButton( 420, 125, 180, 20, 'Вкл/Выкл кэша', false, resourceWindow )
	--local changeMetaButton = GuiButton( 420, 150, 180, 20, 'Сохранить meta.xml', false, resourceWindow )

	local closeButton = GuiButton( 420, 270, 180, 20, 'Назад', false, resourceWindow )

	addEventHandler( 'onClientGUIClick', startResourceButton, function()
		triggerServerEvent( 'Crypt:requestAction', root, 'startResource', resourceName )
	end, false )

	addEventHandler( 'onClientGUIClick', stopResourceButton, function()
		triggerServerEvent( 'Crypt:requestAction', root, 'stopResource', resourceName )
	end, false )

	addEventHandler( 'onClientGUIClick', encryptButton, function()
		local scripts = {}
		local files = {}
		local selectedItems = metaGridList:getSelectedItems()
		for i = 1, #selectedItems, 5 do
			local rowID = selectedItems[i].row
			if metaGridList:getItemText( rowID, 1 ) == 'file' then
				table.insert( files, metaGridList:getItemText( rowID, 2 ) )
			else
				table.insert( scripts, metaGridList:getItemText( rowID, 2 ) )
			end
		end
		if #files ~= 0 then
			createFilesEncryptWindow( resourceName, files )
		end
		if #scripts ~= 0 then
			createCompileWindow( resourceName, scripts )
			if encryptWindow then
				encryptWindow:setVisible( false )
			end
		end
	end, false )

	addEventHandler( 'onClientGUIClick', decryptButton, function()
		local files = {}
		local selectedItems = metaGridList:getSelectedItems()
		for i = 1, #selectedItems, 5 do
			local rowID = selectedItems[i].row
			if metaGridList:getItemText( rowID, 1 ) == 'file' then
				table.insert( files, metaGridList:getItemText( rowID, 2 ) )
			end
		end
		if #files ~= 0 then
			createFilesDecryptWindow( resourceName, files )
		end
	end, false )	

	local updateFilesHandler = function( sourceResourceName, newResourceFiles )
		if sourceResourceName ~= resourceName then
			return false
		end

		metaGridList:clear()
		for i = 1, #newResourceFiles do
			local row = metaGridList:addRow( )
			local fileInfo = newResourceFiles[i]
			metaGridList:setItemText ( row, 1, fileInfo[1] == 1 and 'script' or 'file', false, true )
			metaGridList:setItemText ( row, 2, fileInfo[2], false, true )
			metaGridList:setItemText ( row, 3, fileInfo[4] or 'client', false, true )
			if fileInfo[3] == true or fileInfo[3] == nil then
				metaGridList:setItemText ( row, 4, 'true', false, true )
			else
				metaGridList:setItemText ( row, 4, 'false', false, true )
			end
			if fileInfo[1] == 1 then
				local test
				if fileInfo[5] == 2 then
					text = 'Ком'
				elseif fileInfo[5] == 3 then
					text = 'КомШиф'
				else
					text = '---'
				end
				metaGridList:setItemText ( row, 5, text, false, true )
			else
				metaGridList:setItemText ( row, 5, fileInfo[5] or '---', false, true )
			end
		end
	end

	addEventHandler( 'Crypt:onGetResourceFiles', root, updateFilesHandler )

	triggerServerEvent( 'Crypt:requestAction', root, 'getFileList', resourceName )

	addEventHandler( 'onClientGUIClick', closeButton, function()
		resourceWindow:destroy()
		mainWindow:setVisible( true )
		removeEventHandler( 'Crypt:onGetResourceFiles', root, updateFilesHandler )
	end, false )

end

addEventHandler( 'onClientResourceStart', root, function()
	triggerServerEvent( 'Crypt:requesPermissions', root )
end )

function createErrorWindow( text, windowType )
	local rowCount = 1
	for _ in text:gmatch( '\n' ) do
		rowCount = rowCount + 1
	end
	local sizeAdd = rowCount > 3 and ( ( rowCount - 3 ) * 15 ) or 0

	local errorWindow = GuiWindow( 0, 0, 450, 120 + sizeAdd, 'Внимание', false )
	errorWindow:center()
	errorWindow:setSizable( false )

	local imagePath
	if windowType == 2 then
		imagePath = 'images/warning.png'
	elseif windowType == 3 then
		imagePath = 'images/error.png'
	else
		imagePath = 'images/info.png'
	end
	GuiStaticImage( 15, 35, 48, 48, imagePath, false, errorWindow )
	local textLabel = GuiLabel( 70, 35, 370, 70 + sizeAdd, text, false, errorWindow )
	--textLabel:setHorizontalAlign( 'center' )

	local closeButton = GuiButton( 175, 90 + sizeAdd, 100, 30, 'Закрыть', false, errorWindow )

	showCursor( true )

	addEventHandler( 'onClientGUIClick', closeButton, function()
		errorWindow:destroy()
		if not mainWindow or not isElement( mainWindow ) then
			showCursor( false )
		end
	end, false )

end

addEventHandler( 'Crypt:onGetPermissions', root, function( permissoins, errors )
	if permissoins then
		addCommandHandler( 'cr', createMainWindow )
		if errors and #errors ~= 0 then
			local text = 'Ресурсу Crypt-reload необходимы права:\n'
			for i = 1, #errors do
				text = text .. REQUEST_PERMISSIONS[ errors[i] ] .. '\n'
			end
			text = text .. '\nИспользуй: aclreguest allow Crypt-reload all'
			createErrorWindow( text, 3 )
		end
	else
		removeCommandHandler( 'cr', createMainWindow )
	end
end )

addEventHandler( 'Crypt:onActionError', root, function( code, ... )
	local params = { ... }
	local text = ACTIONS_ERROR_CODES[code]
	if #params ~= 0 then
		for i = 1, #params do
			text:gsub( '&' .. i, params[i] )
		end
	end
	createErrorWindow( text, 2 )
end )

addEventHandler( 'Crypt:onInfo', root, function( text )
	outputChatBox( 'Crypt: ' .. text )
end )