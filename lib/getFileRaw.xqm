module namespace file = 'http://iro37.ru/trac/api/v0.1/u/data/stores/file';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../core/utilits/config.xqm';

import module namespace yandex = 'http://iro37.ru/trac/lib/yandex'
  at 'yandex.xqm';
  
import module namespace nc = 'http://iro37.ru/trac/lib/nextCloud'
  at 'nextcloud.xqm';  
  
import module namespace 
  ncOAuth2 = 'http://iro37.ru/trac/api/v0.1/u/data/stores/nextCloudOAuth2s'
    at '../endpoints/v0.1/p.data.GET.resource.oauth-token.xqm';
    
(: возвращает файл в формате base64 :)
declare function file:getFileRaw(
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