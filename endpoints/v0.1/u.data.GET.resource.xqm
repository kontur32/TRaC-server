module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';
  
import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at '../../core/permissions/auth.xqm';

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
    
    let $store := 
      $data
      [ row[ ends-with( @id, $storeID ) ] ][ last() ]

    return
      switch ( $store/row/@type/data() )
      case 'http://dbx.iro37.ru/zapolnititul/Онтология/хранилищеЯндексДиск'
        return
          data:yandex( $data, $store, $path )
      default
        return
          <err:RES02>Тип хранилища не зарегистрирован</err:RES02>
  };
  
declare function data:yandex( $data, $store, $path ){    
    let $token := 
      $store/row/cell[ @id = "http://dbx.iro37.ru/zapolnititul/сущности/токенДоступа" ]/text()
    let $storePath :=
      $store/row/cell[ @id = "http://dbx.iro37.ru/zapolnititul/признаки/локальныйПуть" ]/text()
      
    let $fullPath := iri-to-uri( $storePath ) || $path
    let $href :=
      http:send-request(
         <http:request method='GET'>
           <http:header name="Authorization" value="{ 'OAuth ' || $token }"/>
           <http:body media-type = "text" >              
            </http:body>
         </http:request>,
         web:create-url(
           'https://cloud-api.yandex.net:443/v1/disk/resources',
           map{
             'path' : $fullPath,
             'limit' : '50'
           }
         )
      )[2]/json/file/text()
   let $response :=
      if( $href )  
    then(
      let $rawData := fetch:binary( $href ) 
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
              "http://iro37.ru:9984/ooxml/api/v1.1/xlsx/parse/workbook"
          )
      return
       $response[ 2 ]
     )
     else(
       <err:RES01>Ресурс не найден</err:RES01>
     ) 
     
   return
     $response
};