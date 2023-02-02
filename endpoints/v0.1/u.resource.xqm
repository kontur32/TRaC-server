module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data/stores';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';

import module namespace file = 'http://iro37.ru/trac/api/v0.1/u/data/stores/file'
  at '../../lib/getFileRaw.xqm';

import module namespace sch = "http://iro37.ru/trac/api/v0.1/u/data/stores/modelRDF"
  at 'lib/modelRDF.xqm';
  
import module namespace rdf = "http://iro37.ru/trac/api/v0.1/u/data/stores/trciToRDF"
  at 'lib/trciToRDF.xqm';

declare variable 
  $data:зарезервированныеПараметрsЗапроса := ('xq', 'starts', 'limit');

declare variable 
  $data:parseEndpoint :=
    'http://' || request:hostname() || ':' || request:port() ||
    "/ooxml/api/v1.1/xlsx/parse/workbook";

declare variable  $data:разеделитель := ';';

(:
  Парсит xlsx-файл по страницам с применением одной схемы ко всем страницам
  @param page список имен страниц, разделенных точкой с запятой
:)
declare
  %public
  %rest:method('GET')
  %rest:query-param('path', '{$path}')
  %rest:query-param('xq', '{$query}', '.')
  %rest:query-param('schema', '{$schema}', '')
  %rest:query-param('page', '{$page}', '')
  %rest:query-param("access_token", "{$access_token}", "")
  %output:method('xml')
  %rest:path( '/trac/api/v0.2/u/data/stores/{$storeID}/rdf')
function
  data:get3(
    $path as xs:string*,
    $query as xs:string*,
    $storeID,
    $schema,
    $page,
    $access_token as xs:string*
  )
  {
    let $pages := tokenize($page, ';')
    let $data :=
      data:get($path, $storeID)
      /file/table[
        if(empty($pages))then(1)else(@label=$pages)
      ]
    let $schema := sch:model(fetch:xml($schema)/csv)
    return
      <result>{
        for $i in $data
        return
          rdf:rdf(rdf:trci($i, $schema))
      }</result>
  };

declare
  %public
  %rest:method('GET')
  %rest:query-param('path', '{$path}')
  %rest:query-param('xq', '{$query}', '.')
  %rest:query-param('schema', '{$schema}', '')
  %rest:query-param('page', '{$page}', '')
  %rest:query-param("access_token", "{$access_token}", "")
  %output:method('xml')
  %rest:path('/trac/api/v0.1/u/data/stores/{$storeID}/rdf')
function
  data:get2(
    $path as xs:string*,
    $query as xs:string*,
    $storeID,
    $schema,
    $page,
    $access_token as xs:string*
  )
  {
    let $data :=
      data:get($path,$storeID)
      /file/table[
        if($page!='')then(@label=$page)else(1)
      ]
    let $schema := sch:model(fetch:xml($schema)/csv)
    return
      rdf:rdf(rdf:trci($data, $schema))
  };


(:
  Возвращает ресурсы, указанные в $path через точку с запятой 
  из хранилища $storeID в формате TRCI
:)
declare
  %public
  %rest:method('GET')
  %rest:query-param('path', '{$path}')
  %rest:path('/trac/api/v0.1/u/data/stores/{$storeID}')
function data:get(
  $path as xs:string*,
  $storeID as xs:string
) as element(file)*
{
  for $i in tokenize($path, $data:разеделитель)
  let $rawData := data:fileRaw(normalize-space($i), $storeID)
  where $rawData instance of xs:base64Binary
  return
    data:trci($rawData)/child::*
};

declare
  %private
  %rest:GET
  %rest:query-param('path', '{$path}')
  %rest:path('/trac/api/v0.1/u/data/stores/{$storeID}/file')
function data:fileRaw(
    $path as xs:string*,
    $storeID as xs:string
)
{
  let $userID := session:get('userID' )
  let $параметрыЗапросаДанных :=
    map{'имяПеременойПараметров':'params', 'значенияПараметров':map{}}
  let $storeRecord := 
    читатьБД:данныеПользователя(
      $userID, 1, 0, '.', $параметрыЗапросаДанных
    )?шаблоны[row[ends-with(@id, $storeID)]]
  return
     file:getFileRaw($storeRecord, $path) 
};

(: конвертирует base64Binary в TRCI :) 
declare
  %private
function data:trci($rawData as xs:base64Binary) as document-node()
{
  let $request := 
      <http:request method='POST'>
        <http:header name="Content-type" value="multipart/form-data"/>
          <http:multipart media-type = "multipart/form-data" >
              <http:header name='Content-Disposition' value='form-data; name="data"'/>
              <http:body media-type = "application/octet-stream">
                {$rawData}
              </http:body>
          </http:multipart> 
        </http:request>
  let $response := http:send-request($request, $data:parseEndpoint)
  return
   $response[2]
};

(: возвращает файл из хранилища в формате TRCI, интерфейс старый :)
declare
  %public
function data:xlsx-to-trci1(
  $storeRecord as element(table),
  $path as xs:string,
  $query as xs:string
){
  let $rawData := file:getFileRaw($storeRecord, $path)
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
      where not($i = $data:зарезервированныеПараметрsЗапроса)
      return map{$i : request:parameter($i)}
    )
  return
    xquery:eval(
      $xq,
      map{'':data:trci($rawData), 'params':$params},
      map{'permission':'none'}
    )
};