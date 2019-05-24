
addEvent( 'Crypt:requesPermissions', true )
addEvent( 'Crypt:requestAction', true )

local function generateFileList( resourceName )
	local pathPrefix = ':' .. resourceName .. '/'

	local meta = XML.load( pathPrefix .. 'meta.xml', true )

	local output = {}

	local cryptData = CryptData.load( resourceName, false )

	for i, node in pairs( meta:getChildren( ) ) do
		local nodeName = node:getName( )
		if nodeName == 'script' then
			-- Проверяем скрипты
			local attributes = node:getAttributes()
			local filePath = attributes['src']

			-- Проверяем закомпилирован ли файл.
			local compyleMode

			local file = File( pathPrefix .. filePath, true )
			if file then
				local fileHead = file:read( 4 )
				if fileHead == '\27\76\117\97' then
					-- Закомпилирован без шифрования
					compyleMode = 2
				elseif fileHead == '\28\77\118\98' then
					-- Закомпилирован с шифрованим
					compyleMode = 3
				else
					-- Не компилирован
					compyleMode = 1
				end
				file:close()
			else
				-- Ошибка открытия
				compyleMode = 0
			end

			table.insert( output, { 1, filePath, attributes['cache'], attributes['type'], compyleMode } )
		elseif nodeName == 'file' then
			-- Проверяем файлы
			local attributes = node:getAttributes()
			local filePath = attributes['src']
			local cryptMode = false
			
			if cryptData and cryptData.data[filePath] then
				cryptMode = cryptData.data[filePath][1]
			end

			table.insert( output, { 2, filePath, attributes['cache'], false, cryptMode } )
		end

	end
	return output
end

addEventHandler( 'Crypt:requestAction', root, function( action, ... )
	local arg = { ... }
	if action == 'startResource' then
		-- Старт ресурса
		if not hasObjectPermissionTo( client, 'command.start', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 1 )
			return false
		end
		if not hasObjectPermissionTo( 'resource.Crypt-reload', 'function.startResource', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 2 )
			return false
		end
		local resource = Resource.getFromName( arg[1] )
		if not resource then
			client:triggerEvent( 'Crypt:onActionError', root, 3, arg[1] )
			return false
		end
		if resource:start() then
			return true
		else
			client:triggerEvent( 'Crypt:onActionError', root, 4 )
			return false
		end
	elseif action == 'stopResource' then
		-- Стоп ресурса
		if not hasObjectPermissionTo( client, 'command.stop', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 5 )
			return false
		end
		if not hasObjectPermissionTo( 'resource.Crypt-reload', 'function.stopResource', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 6 )
			return false
		end
		local resource = Resource.getFromName( arg[1] )
		if not resource then
			client:triggerEvent( 'Crypt:onActionError', root, 3 )
			return false
		end
		if resource:stop() then
			return true
		else
			client:triggerEvent( 'Crypt:onActionError', root, 7 )
			return false
		end
	elseif action == 'getResourcesList' then
		-- Получение списка реурсов
		local output = {}
		for key, resource in pairs( Resource.getAll() ) do
			output[key] = { resource:getName(), resource:getInfo( 'name' ), resource:getState() }
		end
		client:triggerEvent( 'Crypt:onGetResourceList', root, output )

	elseif action == 'getFileList' then
		-- Получение списка файлов ресурса
		local resourceName = arg[1]

		local resource = Resource.getFromName( resourceName )
		if not resource then
			client:triggerEvent( 'Crypt:onActionError', root, 3 )
			return false
		end

		client:triggerEvent( 'Crypt:onGetResourceFiles', root, arg[1], generateFileList( resourceName ) )
	elseif action == 'compileScripts' then
		-- Компиляция скриптов
		local resourceName = arg[1]
		local scripts = arg[2]
		local compile = arg[3]
		local stripDebug = arg[4]
		local obfuscate = arg[5]

		local resource = Resource.getFromName( resourceName )
		if not resource then
			client:triggerEvent( 'Crypt:onActionError', root, 3 )
			return false
		end

		if type( compile ) ~= 'boolean' then
			client:triggerEvent( 'Crypt:onActionError', root, 13 )
			return false
		end

		if type( stripDebug ) ~= 'boolean' then
			client:triggerEvent( 'Crypt:onActionError', root, 14 )
			return false
		end

		if obfuscate ~= 0 and obfuscate ~= 1 and obfuscate ~= 2 then
			client:triggerEvent( 'Crypt:onActionError', root, 8 )
			return false
		end

		if not hasObjectPermissionTo( client, 'function.cryptres', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 18 )
			return false
		end

		local scriptPrefix = ':' .. resourceName .. '/'

		if type( scripts ) ~= 'table' then
			client:triggerEvent( 'Crypt:onActionError', root, 9 )
			return false
		end

		for i = 1, #scripts do
			if not makeBackup( scriptPrefix .. scripts[i] ) then
				client:triggerEvent( 'Crypt:onActionError', root, 10, scriptPrefix .. scripts[i] )
				return false
			end
		end

		for i = 1, #scripts do
			compileScript( scriptPrefix .. scripts[i], compile, stripDebug, obfuscate )
		end
	elseif action == 'refreshReources' then
		-- Обновление состояния ресурсов
		if not hasObjectPermissionTo( client, arg[1] and 'command.refreshall' or 'command.refresh', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, arg[1] and 11 or 12 )
			return false
		end
		if not hasObjectPermissionTo( 'resource.Crypt-reload', 'function.refreshResources', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 12 )
			return false
		end

		return refreshResources( arg[1] )
	elseif action == 'encryptFiles' then
		local resourceName = arg[1]
		local files = arg[2]
		local mode = arg[3]
		local passworld = arg[4]

		local resource = Resource.getFromName( resourceName )
		if not resource then
			client:triggerEvent( 'Crypt:onActionError', root, 3 )
			return false
		end

		if resource:getState( ) == 'running' then
			client:triggerEvent( 'Crypt:onActionError', root, 15 )
			return false
		end

		if type( files ) ~= 'table' then
			client:triggerEvent( 'Crypt:onActionError', root, 16 )
			return false
		end

		if not mode or not cryptMethods[ mode ] then
			client:triggerEvent( 'Crypt:onActionError', root, 17 )
			return false
		end

		if not hasObjectPermissionTo( client, 'function.cryptres', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 18 )
			return false
		end

		for _, fileName in pairs( files ) do
			encryptResourceFile( resource, fileName, mode, passworld, unpack( arg, 5 ) )
		end

		local finishHandler
		finishHandler = function()
			triggerClientEvent( 'Crypt:onGetResourceFiles', root, resourceName, generateFileList( resourceName ) )
			removeEventHandler( 'onCryptFinished', root, finishHandler )
		end

		addEventHandler( 'onCryptFinished', root, finishHandler )

	elseif action == 'decryptFiles' then
		local resourceName = arg[1]
		local files = arg[2]
		local passworld = arg[3]

		local resource = Resource.getFromName( resourceName )
		if not resource then
			client:triggerEvent( 'Crypt:onActionError', root, 3 )
			return false
		end

		if resource:getState( ) == 'running' then
			client:triggerEvent( 'Crypt:onActionError', root, 15 )
			return false
		end

		if type( files ) ~= 'table' then
			client:triggerEvent( 'Crypt:onActionError', root, 16 )
			return false
		end

		if not hasObjectPermissionTo( client, 'function.cryptres', false ) then
			client:triggerEvent( 'Crypt:onActionError', root, 18 )
			return false
		end

		for _, fileName in pairs( files ) do
			decryptResourceFile( resource, fileName, passworld )
		end

		local finishHandler
		finishHandler = function()
			triggerClientEvent( 'Crypt:onGetResourceFiles', root, resourceName, generateFileList( resourceName ) )
			removeEventHandler( 'onCryptFinished', root, finishHandler )
		end

		addEventHandler( 'onCryptFinished', root, finishHandler )
		
	end
end )

local function checkCrypt( )
	local permissions = {
		'general.ModifyOtherObjects';
		'function.fetchRemote';
		'function.startResource';
		'function.stopResource';
		'function.refreshResources';
	};
	local errors = {}
	for id = 1, #permissions do
		if not ACL.hasObjectPermissionTo( 'resource.Crypt-reload', permissions[id], false ) then
			table.insert( errors, id )
		end	
	end
	--[[
	if not File.exists( 'server.key' ) then
		table.insert( errors, 6 )
	end
	]]
	return errors
end

addEventHandler( 'Crypt:requesPermissions', root, function()
	if hasObjectPermissionTo( client, 'function.cryptres', false ) then
		triggerClientEvent( client, 'Crypt:onGetPermissions', root, true, checkCrypt() )
	end
end )

addEventHandler( 'onPlayerLogin', root, function( )
	if hasObjectPermissionTo( source, 'function.cryptres', false ) then
		triggerClientEvent( source, 'Crypt:onGetPermissions', root, true, checkCrypt() )
	end
end )

addEventHandler( 'onPlayerLogout', root, function()
	triggerClientEvent( source, 'Crypt:onGetPermissions', root, hasObjectPermissionTo( source, 'function.cryptres', false ) )
end )
