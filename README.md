# Crypt-reload

Ресурс для защиты файлов на основе шифрования TEA для MTA:SA.
Включает в вебя компилятор скриптов, использующий API luac.mtasa.com

## Установка

1. Изменить все ключи шифрования в ресурсе
2. Загрузить ресурс на сервер, сделать refresh
3. Ввести команду `aclrequest allow Crypt-reload all`
4. Добавить право в ACL `function.cryptres` группам, которые будут шифровать файлы
5. Стартовать ресурс

## Использование

1. Команда `/cr` открывает user friendly интерфейс, где проходит шифрование нужных ресурсов
2. После шифрования (можно сделать и заранее) необходимо написать загрузчик для зашифрованных файлов

### Объекты, модели авто
~~~
exports['Crypt-reload']:load(
  {
  --{ файл, режим, параметры, ... };
    { 'textures.txd', 'txd', { 700, 701 } };
    { 'Model1.dff', 'dff', 700 };
    { 'Model1.col', 'col', 700 };

    { 'Model2.dff', 'dff', 701 };
    { 'Model2.col', 'col', 701 };
  }
)
~~~
### С использованием коллбека

* !!! Колбек функция должна быть прописана в `meta.xml` вашего ресурса как экспротная !!!

~~~
local imageToDraw

function cryptCallback( filepath, texture )
	imageToDraw = texture
end

exports['Crypt-reload']:load(
	'cryptCallback',
	{
		{ 'secret_image', 'texture' };
	}
)

addEventHandler( 'onClientRender', root, function()
	if imageToDraw then
		dxDrawImage( 0, 0, 1366, 768, imageToDraw )
	end
end )
~~~
