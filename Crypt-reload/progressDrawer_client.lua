
local sX, sY = guiGetScreenSize( )

function drawProgress( processValue, processName  )
	dxDrawRectangle( 0, sY - 18, sX, 18, 0xFF7f7f7f )
	dxDrawRectangle( 1, sY - 18, (sX - 2) * processValue, 18, 0xFF187a00 )
	dxDrawText( tostring( processName ), 0, sY - 18, sX, sY, 0xFF000000, 1, 'arial', 'center', 'center' )
end