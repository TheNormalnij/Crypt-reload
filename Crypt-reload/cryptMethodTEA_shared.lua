
CryptMethod{
	name = 'TEA';

	encrypt = function( self, file, passworld )
		local c = 0
		local data = {}
		local fileSize = file:getSize()
		for i = 1, fileSize, 700000 do
			c = c + 1
			data[c] = file:read( 700000 )
			coroutine.yield( 'Шифрование', i / fileSize / 4 )
		end
		coroutine.yield( 'Шифрование', 0.50 )
		data = encodeString( 'tea', table.concat( data ), { key = passworld } )
		coroutine.yield( 'Шифрование', 1.00 )
		return data
	end;

	decrypt = function( self, file, passworld )
		local c = 0
		local data = {}
		local fileSize = file:getSize()
		for i = 1, fileSize, 700000 do
			c = c + 1
			data[c] = file:read( 700000 )
			coroutine.yield( 'Расшифровка', i / fileSize / 4 * 3 )
		end
		local endTick = getTickCount()
		coroutine.yield( 'Расшифровка', 0.85 )
		data = decodeString( 'tea', table.concat( data ), { key = passworld } )
		coroutine.yield( 'Расшифровка', 1.00 )

		return data
	end;

}
