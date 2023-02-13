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

(: возвращает список ресурсов из хранилища по указанному пути :)
declare
  %public
  %rest:method('GET')
  %rest:query-param('output', '{$output}', 'xml')
  %rest:query-param('path', '{$path}')
  %rest:path('/trac/api/v0.1/u/data/stores/{$storeID}/resources')
function
dataRaw:resourcesList(
  $path as xs:string*,
  $output as xs:string,
  $storeID as xs:string
)
{
  let $storeRecord := dataRaw:storeRecord($storeID)
  let $list := yandex:resourceList($storeRecord, $path)
  let $response :=
    switch ($output)
    case 'json'
      return
        json:serialize(
          <json type="object">
            {$list}
          </json>
        )
    case 'xml'
      return
        $list
    default return $list
  return
   (
    <rest:response>
      <http:response status="200">
        <http:header name="Content-type" value='{"application/" || $output}'/>
      </http:response>
    </rest:response>,
    $response 
   )
};

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
  let $storeRecord := dataRaw:storeRecord($storeID )
  return
   (
    <rest:response>
      <http:response status="200">
        <http:header name="Content-type" value="application/octet-stream"/>
      </http:response>
    </rest:response>,
    dataRaw:getFileRaw($storeRecord, $path)
   ) 
};


(: запись с данными хранилища из базы  :)
declare function dataRaw:storeRecord(
  $storeID as xs:string
) as element(table)*
{
  читатьБД:данныеПользователя(
    session:get('userID'), 1, 0,'.',
    map{'имяПеременойПараметров' : 'params', 'значенияПараметров' : map{}}
  )?шаблоны[row[ends-with( @id, $storeID )]]
};


(: возвращает файл в формате base64 :)
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