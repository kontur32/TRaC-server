module namespace dataRaw = 'http://iro37.ru/trac/api/v0.1/u/data/stores/raw';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';
  
import module namespace yandex = 'http://iro37.ru/trac/lib/yandex'
  at '../../lib/yandex.xqm';
  
import module namespace nc = 'http://iro37.ru/trac/lib/nextCloud'
  at '../../lib/nextcloud.xqm';  

import module namespace sch = "http://iro37.ru/trac/api/v0.1/u/data/stores/modelRDF"
  at 'lib/modelRDF.xqm';
  
import module namespace ncOAuth2 = 'http://iro37.ru/trac/api/v0.1/u/data/stores/nextCloudOAuth2'
  at 'p.data.GET.resource.oauth-token.xqm';

declare
  %public
  %rest:method('GET')
  %rest:query-param( 'path', '{$path}' )
  %rest:path( '/trac/api/v0.1/u/data/stores/{$storeID}/file' )
function
dataRaw:getFileRaw_publish(
  $path as xs:string*,
  $storeID as xs:string
)
{
  let $storeRecord := 
    читатьБД:данныеПользователя(
      session:get('userID'), 1, 0,'.',
      map{'имяПеременойПараметров' : 'params', 'значенияПараметров' : map{}}
    )?шаблоны[row[ends-with( @id, $storeID )]]
  return
   (
    <rest:response>
      <http:response status="200">
        <http:header name="Content-type" value="application/octet-stream"/>
      </http:response>
    </rest:response>,
    dataRaw:getFileRaw( $storeRecord, $path )
   ) 
};

(:
  возвращает файл в формате base64
:)
declare function dataRaw:getFileRaw(
  $storeRecord as element(table),
  $path as xs:string*
)
{
  switch ($storeRecord/row/@type/data())
  case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеЯндексДиск'
    return
      yandex:getResource($storeRecord, $path)
  case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеNextcloud'
    return
      nc:getResource($storeRecord,  $config:params?tokenRecordsFilePath, $path)
  case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеNextCloudOauth2'
    return
      ncOAuth2:getFromNextCloud(
        substring-after($storeRecord//row[1]/@id/data(), '#'), 
        $path
      )
  default
    return
      <err:RES02>Тип хранилища не зарегистрирован</err:RES02>
};