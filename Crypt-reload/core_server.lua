
addEvent( 'Crypt:requestCryptData', true )
addEvent( 'Crypt:onCryptFinish', false )

local resourceInfo = {}
local clientResourcesInfo = {}
local thisServerKey = 'YouPrivateResourceKey'
local cryptDataKey = 'PrivateKey'
local isServerCheck = false
local isCheckRequestGet = false

function makeBackup( path, toPath )
	toPath = toPath or string.format( '%s.bak.%d', path, getRealTime().timestamp )
	if File.copy( path, toPath ) then
		outputInfo( 'Сделан бэкап: ' .. toPath )
		return true
	else
		outputInfo( 'Ошибка создания бэкапа: ' .. path )
		return false
	end
end

--

CryptData = {

	resourcesData = {};
	
	load = function( resourceName, create, cache )
		local self = CryptData.resourcesData[resourceName]

		if self then
			return self
		else

			self = setmetatable( 
			{
				name = resourceName;
			}
			, CryptData )

			local filePath = ':' .. resourceName .. '/crypt.lnk'
			if File.exists( filePath ) then
				local file = File( filePath )
				local data = file:read( file:getSize() )
				file:close()
				data = teaDecode( data, thisServerKey )

				if data then
					data = fromJSON( data )
					if data then
						self.data = data
					else
						outputInfo( 'Ошибка расшифровки шифрдаты ресурса ' .. resourceName )
						return false
					end
				else
					outputInfo( 'Ошибка расшифровки шифрдаты ресурса ' .. resourceName )
				end
			elseif create == nil or create then
				self.data = {}
				self.isChanged = true
				outputInfo( 'Создана шифрдата ресурса ' .. resourceName )
			else
				return false
			end
			if cache == nil or cache then
				CryptData.resourcesData[resourceName] = self
				CryptData.clientData = nil
			end
			return self
		end
	end;

	addFile = function( self, filePath, ... )
		if self.data[filePath] then
			outputInfo( 'Невозможно добавить шифрдату для файла ' .. tostring( filePath ) .. ' ресурса ' .. self.name .. '. Файл уже был добавлен' )
			return false
		end
		self.data[filePath] = { ... }
		self.isChanged = true
		self.clientData = nil
		CryptData.clientData = nil
		return true
	end;

	removeFile = function( self, filePath )
		if self.data[filePath] then
			self.data[filePath] = nil
			self.clientData = nil
			CryptData.clientData = nil
			self.isChanged = true
			return true
		end
		outputInfo( 'Невозможно удалить шифрдату для файла ' .. tostring( filePath ) .. ' ресурса ' .. self.name .. '. Файл отсутствует в шифрдате.' )
		return false
	end;

	generateClientData = function( self )
		CryptData.clientData = nil
		self.clientData = teaEncode( toJSON( self.data, true ), cryptDataKey )
		return true
	end;

	save = function( self )
		local filePath = ':' .. self.name .. '/crypt.lnk'
		if File.exists( filePath ) then
			File.delete( filePath )
		end
		local data = toJSON( self.data, true )
		data = teaEncode( data, thisServerKey )
		local file = File.new( filePath )
		file:write( data )
		file:close()
		return true
	end;

	unload = function( self )
		if self.isChanged then
			self:save()
		end
		local resource = Resource.getFromName( self.name )
		if resource:getState( ) ~= 'running' then
			CryptData.resourcesData[ self.name ] = nil
			CryptData.clientData = nil
			return true
		else
			return false
		end
	end;

	unloadUnused = function( )
		for resourceName, resourceData in pairs( CryptData.resourcesData ) do
			local resource = Resource.getFromName( resourceName )
			if resource:getState( ) ~= 'running' then
				resourceData:unload()
			end
		end
	end;

	saveAll = function( )
		for resourceName, resourceData in pairs( CryptData.resourcesData ) do
			if resourceData.isChanged then
				resourceData:save()
			end
		end
	end;
}

CryptData.__index = CryptData

addEventHandler( 'Crypt:requestCryptData', root, function( )
	local client = client
	local data = CryptData.clientData
	if not data then
		data = {}
		for resourceName, resourceData in pairs( CryptData.resourcesData ) do
			if resourceData.clientData then
				data[resourceName] = resourceData.clientData
			else
				resourceData:generateClientData()
				data[resourceName] = resourceData.clientData
			end
		end

		CryptData.clientData = data
	end
	triggerClientEvent( client, 'Crypt:onGetCryptData', root, data )
end )


addEventHandler( 'onResourceStop', root, function( stopResource )
	if stopResource == resource then
		CryptData.saveAll()
	else
		local resourceName = stopResource:getName()
		local resourceData = CryptData.load( resourceName, false )
		if resourceData then
			resourceData:unload()
		end	
	end
end )

--

local compileStack = {}
local isCompileProcessed = false

local compileNextFile
local function compiledCallBack( data, info, scriptPath )
	isCompileProcessed = false
	if info.success then

	else
		outputInfo( 'Ошибка компиляциии. HTTP STATUS: ' .. info.statusCode )
	end
	if File.exists( scriptPath ) then
		File.delete( scriptPath )
	end
	script = File.new( scriptPath )
	script:write( data )
	script:close()
	outputInfo( scriptPath .. ' получено и сохранено' )
	compileNextFile()
end

function compileNextFile( )
	if not isCompileProcessed then
		local info = table.remove( compileStack )
		if info then
			local script = File( info[1], true )

			if not script then
				outputInfo( 'Ошибка открытия: ' .. filePath )
				script:close()
				return false
			end

			local fileContent = script:read( script:getSize() )
			fetchRemote ( 'http://luac.mtasa.com/?compile=' .. (info[2] and 1 or 0).. '&debug=' .. (info[3] and 1 or 0) ..'&obfuscate=' .. info[4],
				{
					['queueName'] = 'Crypt-reload compile';
					['postData'] = fileContent;
					['postIsBinary'] = true;
					['method'] = 'POST';
				},
				compiledCallBack,
				{ info[1] }
			)

			isCompileProcessed = true
		end
	end
end

function compileScript( filePath, compile, debug, obfuscate )
	local script = File( filePath, true )
	if not script then
		outputInfo( 'Ошибка открытия: ' .. filePath )
		script:close()
		return false
	end

	local fileHead = script:read( 4 )
	if fileHead == '\27\76\117\97' then
		outputInfo( 'Уже был закомпилирован, отмена операции: ' .. filePath )
		script:close()
		return false
	elseif fileHead == '\28\77\118\98' then
		outputInfo( 'Уже был закомпилирован, отмена операции: ' .. filePath )
		script:close()
		return false
	end

	script:close()

	if type( compile ) ~= 'boolean' then
		outputInfo( 'Ошибка компиляциии, неверные параметры: ' .. filePath )
		return false
	end
	if type( debug ) ~= 'boolean' then
		outputInfo( 'Ошибка компиляциии, неверные параметры: ' .. filePath )
		return false
	end
	if obfuscate ~= 0 and obfuscate ~= 1 and obfuscate ~= 2 then
		outputInfo( 'Ошибка компиляциии, неверные параметры: ' .. filePath )
		return false
	end

	for i = 1, #compileStack do
		if compileStack[i][1] == filePath then
			outputInfo( 'Ошибка компиляциии, файл уже находится в задании: ' .. filePath )
			return false
		end
	end

	table.insert( compileStack, { filePath, compile, debug, obfuscate } )

	compileNextFile()

	return true
end

local encryptStack = {}
local decryptStack = {}
local processTimer
local processCoroutine

local function stackParsing( )
	while true do
		local encrypt = table.remove( encryptStack, 1 )
		if encrypt then
			local resourceName = encrypt[1]
			local fileName = encrypt[2]
			local filePath =':' .. resourceName .. '/' .. fileName
			local mode = encrypt[3]
			local passworld = encrypt[4]
			if File.exists( filePath ) then
				outputInfo( '"' .. filePath .. '" шифрование начато' )

				local resourceCryptData = CryptData.load( resourceName, true, true )
				if resourceCryptData and resourceCryptData:addFile( fileName, mode, passworld, unpack( encrypt, 5 ) ) then
					cryptMethods[mode]:encryptFile( filePath, passworld, unpack( encrypt, 5 ) )
				else
					outputInfo( '"' .. filePath .. '" шифровка пропущена' )
				end

				outputInfo( '"' .. filePath .. '" шифрование завершено' )
			else
				outputInfo( '"' .. filePath .. '". Файл удален?' )
			end
		end
		local decrypt = table.remove( decryptStack, 1 )
		if decrypt then
			local resourceName = decrypt[1]
			local fileName = decrypt[2]
			local filePath =':' .. resourceName .. '/' .. fileName
			local mode = decrypt[3]
			local passworld = decrypt[4]
			if File.exists( filePath ) then
				outputInfo( '"' .. filePath .. '" расшифровка началась' )
				local resourceCryptData = CryptData.load( resourceName, true, true )
				if resourceCryptData and resourceCryptData:removeFile( fileName ) then
					cryptMethods[mode]:decryptFile( filePath, passworld, unpack( decrypt, 5 ) )
				else
					outputInfo( '"' .. filePath .. '" расшифровка пропущена' )
				end

				outputInfo( '"' .. filePath .. '" расшифровка завершена' )
			else
				outputInfo( '"' .. filePath .. '". Файл удален?' )
			end
		end
		if not decrypt and not encrypt then
			CryptData.unloadUnused()
			triggerEvent( 'Crypt:onCryptFinish', root )
			return true
		end
	end
end

function startCrypt( )
	if processTimer and isTimer( processTimer ) then
		return
	end
	processCoroutine = coroutine.create( stackParsing )
	processTimer = Timer( function()
		if coroutine.status( processCoroutine ) == 'dead' then
			processTimer:destroy()
			processTimer = nil
		else
			--local h1, h2, h3 = debug.gethook() -- против сообщения infinite running
			debug.sethook( processCoroutine )
			local _, processName, processValue = coroutine.resume( processCoroutine )
			outputInfo( 'Процесс: ' .. tostring( processName ) )
			collectgarbage( 'collect' ) -- вызывает сборщик мусора	
		end
	end, 150, 0 )
end

function encryptResourceFile( resource, filePath, mode, passworld, ... )
	if getUserdataType( resource ) ~= 'resource-data' then
		return false, 2
	end

	if resource:getState( ) == 'running' then
		return false, 5
	end

	local resourceName = resource:getName()

	local resourceCryptData = CryptData.load( resourceName, true, false )
	if resourceCryptData and resourceCryptData.data[filePath] then
		return false, 3
	end

	local filePathAbsolute = ':' .. resourceName .. '/' .. filePath

	if not passworld or passworld == '' then
		passworld = ''
		local charSets = { { 48, 57 }, { 65, 90 }, { 97, 122 } }
		local charSetsCount = #charSets
		for i = 1, math.random( 12, 16 ) do
			local chars = charSets[ math.random( 1, charSetsCount ) ]
			passworld = passworld .. string.char( math.random( chars[1], chars[2] ) )
		end
	end
	
	-- Делаем резервную копию

	if not makeBackup( filePathAbsolute ) then
		return false, 6
	end

	table.insert( encryptStack, { resourceName, filePath, mode, passworld, ... } )

	startCrypt()
	return true
end

function decryptResourceFile( resource, filePath, passworld, ... )
	if getUserdataType( resource ) ~= 'resource-data' then
		return false, 1
	end

	local resourceName = resource:getName()
	local resourceCryptData = CryptData.load( resourceName, true, false )

	if not resourceCryptData or not resourceCryptData.data[filePath] then
		return false, 2
	end

	if resourceCryptData.data[filePath][2] ~= passworld then
		outputInfo( 'Неверный пароль' )
		return false, 3
	end

	table.insert( decryptStack, { resourceName, filePath, unpack( resourceCryptData.data[filePath] ) } )
	startCrypt()
end

addEventHandler( 'onResourceStart', root, function( startedResource )
	if resource ~= startedResource then
		CryptData.load( startedResource:getName(), false, true )
	end
end )

function outputInfo( text )
	outputServerLog( 'CRYPT-RELOAD: ' .. text )
	local cryptPlayers = {}
	for _, player in pairs( getElementsByType( 'player' ) ) do
		if hasObjectPermissionTo( player, 'function.cryptres', false ) then
			table.insert( cryptPlayers, player )
		end
	end
	if #cryptPlayers ~= 0 then
		triggerClientEvent( cryptPlayers, 'Crypt:onInfo', root, text )
	end
end
