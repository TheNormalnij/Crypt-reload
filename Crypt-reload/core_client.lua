
addEvent( 'Crypt:onGetCryptData', true )

local cryptDataKey = 'PrivateKey'

local loadMods = {
	txd = function( file, models, filteringEnabled )
		local txd = engineLoadTXD( file, filteringEnabled )
		if type( models ) == 'table' then
			for i = 1, #models do
				engineImportTXD( txd, models[i] )
			end
		else
			engineImportTXD( txd, models )
		end
		return txd
	end;
	dff = function( file, model, alphaTransparency, LOD )
		local dff = engineLoadDFF( file, model )
		engineReplaceModel( dff, model, alphaTransparency )
		engineSetModelLODDistance( model, LOD or 1000 )
		return dff
	end;
	col = function( file, model )
		local COL = engineLoadCOL( file )
		engineReplaceCOL( COL, model )
		return COL
	end;
	texture = function( rawData, ... )
		return DxTexture( rawData, ... )
	end;
	raw = function( rawData )
		return rawData
	end;
}

local decryptStack = {}
local decryptionData = {}

local isCryptDataRequested = false
local process = false

local function getAviableDecryptResource()
	for resourceName in pairs( decryptStack ) do
		if decryptionData[resourceName] then
			return resourceName
		elseif not isCryptDataRequested then
			isCryptDataRequested = true
			triggerServerEvent( 'Crypt:requestCryptData', root )
		end
	end
	return false
end

local h1, h2, h3 = debug.gethook() -- против сообщения infinite running

function stackParsing( )
	while true do
		local resourceName

		while true do
			resourceName = getAviableDecryptResource()

			if resourceName then
				break;
			elseif next( decryptStack ) then
				coroutine.yield( 'Ждет', 0 )
			else
				process = false
				--collectgarbage( 'collect' ) -- вызывает сборщик мусора
				return true
			end

		end

		local resource = getResourceFromName( resourceName )

		if resource:getState( ) == 'running' then
			local decryptTask = decryptStack[resourceName]
			local filePrefix = ':' .. resourceName .. '/'
			local decryptionData = fromJSON( teaDecode( decryptionData[resourceName], cryptDataKey ) )
			local dynamicElementRoot = resource:getDynamicElementRoot()

			while true do
				local task = table.remove( decryptTask, 1 )
				if task then
					local fileName = task[1]
					local loadMode = task[2]
					local fileDecryptionData = decryptionData[fileName]
					
					if fileDecryptionData then
						local loadResul
						
						if File.exists( filePrefix .. fileName ) then
							local file = File( filePrefix .. fileName )
							local decryptedData = cryptMethods[ fileDecryptionData[1] ]:decrypt( file, unpack( fileDecryptionData, 2 ) )
							loadResul = loadMods[ task[2] ]( decryptedData, unpack( task, 3 ) )
							file:close()
						else
							outputDebugString( 'Ошибка открытия ' .. filePrefix .. fileName )
							loadResul = false
						end

						if resource:getState() == 'running' then
							if type( loadResul ) == 'userdata' and getUserdataType( loadResul ) == 'element' then
								loadResul:setParent( dynamicElementRoot )
							end

							if task.callBack then
								call( resource, task.callBack, fileName, loadResul )
							end
						end
					else
						outputDebugString( 'Ошибка расшифровки ' .. filePrefix .. fileName )
					end
				else
					break;
				end
			end
		end
		decryptStack[resourceName] = nil
		resourceName = nil;

	end
end

local function decrypting()
	if process then
		debug.sethook( process )
		local status, processName, processValue = coroutine.resume( process )

		processValue = processValue or 1
		processName = processName or 'Готово'
		drawProgress( processValue, processName )
	else
		removeEventHandler( 'onClientRender', root, decrypting )
		debug.sethook( _, h1, h2, h3 )
	end

end

local function startDecrypt()
	if process and coroutine.status( process ) ~= 'dead' or next( decryptStack ) == nil then
		return
	end
	process = coroutine.create( stackParsing )
	if process then
		addEventHandler( 'onClientRender', root, decrypting )
	end
end

addEventHandler( 'Crypt:onGetCryptData', root, function( data )
	decryptionData = data
	isCryptDataRequested = false
	startDecrypt()
end )

addEventHandler( 'onClientResourceStart', resourceRoot, function(  )
	isCryptDataRequested = true
	triggerServerEvent( 'Crypt:requestCryptData', root )
end )

--------------------------------
--	         EXPORT           --
--------------------------------

function load( ... )
	local arg = { ... }

	local callBackName
	local files
	if type( arg[1] ) == 'string' then
		callBackName = arg[1]
		files = arg[2]
	else
		files = arg[1]
	end
	if files and type( files ) == 'table' then
		local resourceName = sourceResource:getName()

		local thisResourceStack = decryptStack[resourceName]
		if thisResourceStack then
			thisResourceStack = decryptStack[resourceName]
		else
			thisResourceStack = {}
			decryptStack[resourceName] = thisResourceStack
		end
		for i = 1, #files do
			local task = files[i]
			task.callBack = callBackName
			table.insert( thisResourceStack, task )
		end
		startDecrypt()
	else
		outputDebugString( 'Неверные параметры для шифрования ресура ' .. sourceResource:getName(), 2 )
		return false
	end
end


--[[
exports['Crypt-reload']:load(
	cryptCallback,
	{
		{ 'image.png', 'texture' };
		{ 'image2.png', 'texture' };
	}
)
]]
