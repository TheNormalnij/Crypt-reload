
cryptMethods = {}

local writeStep = 0x5FF00

local cryptMethodShared = {

	encryptFile = function( self, filePath, passworld, ... )

		local file = File( filePath )

		if file then

			local data = self:encrypt( file, passworld, ... )
			file:close()

			File.delete( filePath )

			file = File.new( filePath )

			local fileSize = #data
			for i = 1, fileSize, writeStep do
				file:write( data:sub( i, i + writeStep - 1 ) )
				coroutine.yield( 'Cохранение', i / fileSize )
			end
			file:close()
			coroutine.yield( 'Cохранение', 1.0 )
			return true
		else
			outputInfo( 'Ошибка шифрования: Нет такого файла ' .. tostring( filePath ) )
			return false
		end
	end;

	decryptFile = function( self, filePath, passworld, ... )

		local file = File( filePath )

		if file then

			local data = self:decrypt( file, passworld, ... )
			file:close()

			File.delete( filePath )

			file = File.new( filePath )

			local fileSize = #data
			for i = 1, fileSize, writeStep do
				file:write( data:sub( i, i + writeStep - 1 ) )
				coroutine.yield( 'Cохранение', i / fileSize )
			end
			file:close()
			coroutine.yield( 'Cохранение', 1.0 )
			return true
		else
			outputInfo( 'Ошибка расшифровки: Нет такого файла ' .. tostring( filePath ) )
			return false
		end
	end;
}

cryptMethodShared.__index = cryptMethodShared

function CryptMethod( method )
	setmetatable( method, cryptMethodShared )
	cryptMethods[ method.name ] = method
end
