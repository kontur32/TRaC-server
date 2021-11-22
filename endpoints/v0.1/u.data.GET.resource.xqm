module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data/stores';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';

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
  
declare variable 
  $data:зарезервированныеПараметрsЗапроса := 
    ( 'access_token', 'xq', 'starts', 'limit' );


declare
  %public
  %rest:method( 'GET' )
  %rest:query-param( 'path', '{ $path }' )
  %rest:query-param( 'xq', '{ $query }', '.' )
  %rest:query-param( 'schema', '{ $schema }', '' )
  %rest:query-param( "access_token", "{ $access_token }", "" )
  %output:method('xml')
  %rest:path( '/trac/api/v0.1/u/data/stores/{ $storeID }/rdf' )
function
  data:get2(
    $path as xs:string*,
    $query as xs:string*,
    $storeID,
    $schema,
    $access_token as xs:string*
  )
  {
    let $data := data:get($path, $query, $storeID, $access_token)/file/table[1]
    let $schema := sch:model(fetch:xml($schema)/csv)
    return
      rdf:rdf(rdf:trci($data, $schema))
  };

(:
  Возвращает ресурс $path из Яндекс-хранилища $storeID 
  в формате TRCI или сообщение об ошибке
:)

declare
  %public
  %rest:method( 'GET' )
  %rest:query-param( 'path', '{ $path }' )
  %rest:query-param( 'xq', '{ $query }', '.' )
  %rest:query-param( "access_token", "{ $access_token }", "" )
  %rest:path( '/trac/api/v0.1/u/data/stores/{ $storeID }' )
function
  data:get(
    $path as xs:string*,
    $query as xs:string*,
    $storeID,
    $access_token as xs:string*
  )
  {
    let $данныеПользователя :=
      читатьБД:данныеПользователя(
        session:get( 'userID' ), 1, 0,'.',
        map{ 'имяПеременойПараметров' : 'params', 'значенияПараметров' : map{}  }
      )?шаблоны
    
    let $storeRecord := 
      $данныеПользователя[ row[ ends-with( @id, $storeID ) ] ]
    
    let $f :=
      function( $p ){ data:xlsx-to-trci( $p?storeRecord, $p?path, $p?query ) }
    
    return
      if( request:parameter( 'nocache' ) )
      then( data:xlsx-to-trci( $storeRecord, $path, $query ) )
      else(
        let $uri :=
          request:uri() || $path || $query ||  session:get( 'userID' )
        return
          data:getResource(
            $uri, $f, map{ 'storeRecord' : $storeRecord, 'path' : $path, 'query' : $query }
          )
      )
  };

declare function data:getResource( $uri, $funct, $params ){
  let $hash :=  xs:string( xs:hexBinary( hash:md5( $uri ) ) )
  let $resPath := config:param( 'cache.dir' ) || $hash
  let $isCached :=
       if( file:exists( $resPath ) )
       then(
          minutes-from-duration(
           current-dateTime() - file:last-modified( $resPath )
         ) < 5
       )
       else( false() )

  let $cache := 
    if( $isCached  )
    then( try{ doc( $resPath ) }catch*{} )
    else( false() )
   
  return
    if( $cache )
    then( $cache )
    else(
      let $res3 := try{ $funct( $params ) }catch*{}
      let $w := file:write( config:param( 'cache.dir' ) || $hash, $res3 )
      return
         $res3
    )
};


declare
  %public
  %rest:method( 'GET' )
  %rest:query-param( 'path', '{ $path }' )
  %rest:query-param( 'xq', '{ $query }' )
  %rest:path( '/trac/api/v0.1/u/data/stores/{ $storeID }/file' )
function
  data:getFileRaw(
    $path as xs:string*,
    $query as xs:string*,
    $storeID
  )
  {
    let $storeRecord := 
      читатьБД:данныеПользователя(
        session:get( 'userID' ), 1, 0,'.',
        map{ 'имяПеременойПараметров' : 'params', 'значенияПараметров' : map{}  }
      )?шаблоны[ row[ ends-with( @id, $storeID ) ] ]
    return
       data:getFileRaw( $storeRecord, $path ) 
  };



(:
  возвращает файл в формате base64
:)
declare function data:getFileRaw(  $storeRecord as element( table ), $path as xs:string* )
  as xs:base64Binary
{
  switch ( $storeRecord/row/@type/data() )
  case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеЯндексДиск'
    return
      yandex:getResource( $storeRecord, $path )
  case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеNextcloud'
    return
      nc:getResource( $storeRecord,  $config:params?tokenRecordsFilePath, $path )
  default
    return
      <err:RES02>Тип хранилища не зарегистрирован</err:RES02>
};
  
declare function data:trci( $rawData ){
  let $request := 
          <http:request method='POST'>
              <http:header name="Content-type" value="multipart/form-data; boundary=----7MA4YWxkTrZu0gW"/>
              <http:multipart media-type = "multipart/form-data" >
                  <http:header name='Content-Disposition' value='form-data; name="data"'/>
                  <http:body media-type = "application/octet-stream">
                     { $rawData }
                  </http:body>
              </http:multipart> 
            </http:request>
      let $response := 
          http:send-request(
              $request,
              'http://' || request:hostname() || ':' || request:port() || "/ooxml/api/v1.1/xlsx/parse/workbook"
          )
      return
       $response[ 2 ]
};

(: возвращает данные, запрошенные пользователем из базы :)

declare
  %public
function data:xlsx-to-trci(
  $storeRecord as element( table ),
  $path as xs:string,
  $query as xs:string
){
  let $rawData := data:getFileRaw(  $storeRecord, $path )
  let $xq :=
        let $q := 
          if( matches( $query, '^http[s]{0,1}://' ) )
          then( fetch:text( $query ) )
          else( $query )
        return
          if( try{ xquery:parse( $q ) } catch*{ false() } )
          then( $q )
          else( '.' )
    
    let $params := 
      map:merge(
        for $i in request:parameter-names()
        where not( $i = $data:зарезервированныеПараметрsЗапроса )
        return map{ $i : request:parameter( $i ) }
      )
     return
       xquery:eval(
        $xq,
        map{ '' : data:trci( $rawData ),  'params' : $params },
        map{ 'permission' : 'none' }
      )
};