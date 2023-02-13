module namespace dataRDF = 'http://iro37.ru/trac/api/v0.1/u/data/stores/rdf';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data/stores'
  at 'u.data.GET.resource.xqm';

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';
  
import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at '../../core/permissions/auth.xqm';

import module namespace yandex = 'http://iro37.ru/trac/lib/yandex'
  at '../../lib/yandex.xqm';
  
import module namespace nc = 'http://iro37.ru/trac/lib/nextCloud'
  at '../../lib/nextcloud.xqm';  

import module namespace sch = "http://iro37.ru/trac/api/v0.1/u/data/stores/modelRDF"
  at 'lib/modelRDF.xqm';
  
import module namespace rdf = "http://iro37.ru/trac/api/v0.1/u/data/stores/trciToRDF"
  at 'lib/trciToRDF.xqm';
  
import module namespace ncOAuth2 = 'http://iro37.ru/trac/api/v0.1/u/data/stores/nextCloudOAuth2'
  at 'p.data.GET.resource.oauth-token.xqm';
  

(:
  Парсит xlsx-файл по страницам с применением одной схемы ко всем страницам
  @param page список имен страниц, разделенных точкой с заятой
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
  dataRDF:get2(
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
      data:get($path, $query, $storeID, $access_token)
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
  dataRDF:get(
    $path as xs:string*,
    $query as xs:string*,
    $storeID  as xs:string,
    $schema  as xs:string,
    $page,
    $access_token as xs:string*
  )
  {
    let $data :=
      data:get($path, $query, $storeID, $access_token)
      /file/table[if($page!='')then(@label=$page)else(1)]
    let $schema := sch:model(fetch:xml($schema)/csv)
    return
      rdf:rdf(rdf:trci($data, $schema))
  };