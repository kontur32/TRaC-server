module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data/stores';

import module namespace dataRaw = 'http://iro37.ru/trac/api/v0.1/u/data/stores/raw'
  at 'u.data.GET.resource.raw.xqm';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';

declare variable 
  $data:зарезервированныеПараметрsЗапроса := 
    ('access_token', 'xq', 'starts', 'limit');

(:
  Возвращает ресурс $path из Яндекс-хранилища $storeID 
  в формате TRCI или сообщение об ошибке
:)
declare
  %public
  %rest:GET
  %rest:query-param('path', '{$path}')
  %rest:query-param("column-direction", "{$column-direction}")
  %rest:query-param('xq', '{$query}', '.')
  %rest:query-param("access_token", "{$access_token}", "")
  %rest:path('/trac/api/v0.1/u/data/stores/{$storeID}')
function
data:get(
  $path as xs:string*,
  $column-direction as xs:string*,
  $query as xs:string*,
  $storeID,
  $access_token as xs:string*
)
{
  let $данныеПользователя :=
    читатьБД:данныеПользователя(
      session:get('userID'), 1, 0,'.',
      map{'имяПеременойПараметров' : 'params', 'значенияПараметров' : map{}}
    )?шаблоны  
  let $storeRecord := $данныеПользователя[row[ends-with(@id, $storeID)]]
  return
    data:xlsx-to-trci($storeRecord, $path, $column-direction, $query)
};

(: возвращает данные, запрошенные пользователем из базы :)
declare
  %public
function data:xlsx-to-trci(
  $storeRecord as element(table),
  $path as xs:string,
  $column-direction as xs:string*,
  $query as xs:string
){
  let $rawData := dataRaw:getFileRaw($storeRecord, $path)
  let $xq :=
    let $q := 
      if(matches($query, '^http[s]{0,1}://'))
      then(fetch:text($query))
      else($query)
    return
      if(try{xquery:parse($q)}catch*{false()})
      then($q)
      else('.')
    
    let $params := 
      map:merge(
        for $i in request:parameter-names()
        where not( $i = $data:зарезервированныеПараметрsЗапроса )
        return map{ $i : request:parameter( $i ) }
      )
     return
       xquery:eval(
        $xq,
        map{'' : data:trci($rawData, $column-direction),  'params' : $params},
        map{'permission' : 'none'}
      )
};

declare
  %public
function data:trci(
  $rawData as xs:base64Binary
) as element(file)
{
   data:trci($rawData, ())
};

declare
  %public
function data:trci(
  $rawData as xs:base64Binary,
  $column-direction as xs:string*
)
{
  let $endppoint :=
    if(config:param('ooxmlHost'))
    then(config:param('ooxmlHost'))
    else('http://' || request:hostname() || ':' || request:port())
  
  let $request := 
    <http:request method='POST'>
      <http:header name="Content-type" value="multipart/form-data; boundary=----7MA4YWxkTrZu0gW"/>
      <http:multipart media-type = "multipart/form-data" >
        <http:header name='Content-Disposition' value='form-data; name="data"'/>
        <http:body media-type = "application/octet-stream">{$rawData}</http:body>
        <http:header name='Content-Disposition' value='form-data; name="column-direction"'/>
        <http:body media-type = "text/plain">{$column-direction}</http:body>
      </http:multipart> 
      </http:request>
  let $response := 
      http:send-request(
        $request,
        $endppoint || "/ooxml/api/v1.1/xlsx/parse/workbook"
      )
  return
   $response[2]
};

