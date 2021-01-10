module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';
  
import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at '../../core/permissions/auth.xqm';

import module namespace yandex = 'http://iro37.ru/trac/lib/yandex'
  at '../../lib/yandex.xqm';
  
import module namespace nc = 'http://iro37.ru/trac/lib/nextCloud'
  at '../../lib/nextcloud.xqm';  

(:
  Возвращает ресурс $path из Яндекс-хранилища $storeID 
  в формате TRCI или сообщение об ошибке
:)

declare
  %public
  %rest:method( 'GET' )
  %rest:query-param( 'path', '{ $path }' )
  %rest:query-param( "access_token", "{ $access_token }", "" )
  %rest:path( '/trac/api/v0.1/u/data/stores/{ $storeID }' )
function
  data:get(
    $path as xs:string*,
    $storeID,
    $access_token as xs:string*
  )
  {
    let $authorization := 
      if ( $access_token != "")
      then( "Bearer " || $access_token )
      else ( request:header( "Authorization" ) )
      
    let $userID := auth:userID( $authorization )
    
    let $data := 
      читатьБД:всеДанныеПользователя( $userID )
      [ @status = 'active' ]
    
    let $storeRecord := 
      $data
      [ row[ ends-with( @id, $storeID ) ] ][ last() ]

    let $rawData :=
      switch ( $storeRecord/row/@type/data() )
      case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеЯндексДиск'
        return
          yandex:getResource( $storeRecord, $path )
      case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеNextcloud'
        return
          nc:getResource( $storeRecord, "C:\Users\kontu\Downloads\token.xml", $path )
      default
        return
          <err:RES02>Тип хранилища не зарегистрирован</err:RES02>
     return
       if( 0 )
       then( $rawData )
       else(
         data:trci( $rawData )
       )
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