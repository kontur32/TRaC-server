module namespace yandex = 'http://iro37.ru/trac/lib/yandex';

declare function yandex:getResource( $storeRecord, $path ){    
    let $token := 
      $storeRecord/row/cell[ @id = "http://dbx.iro37.ru/zapolnititul/сущности/токенДоступа" ]/text()
    let $storePath :=
      $storeRecord/row/cell[ @id = "http://dbx.iro37.ru/zapolnititul/признаки/локальныйПуть" ]/text()
    
    let $path :=  starts-with( $path, '/' ) ?? $path !! '/' || $path 
    let $fullPath := $storePath || $path
    
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
        return
          $rawData
       )
       else(
         <err:RES01>Ресурс не найден</err:RES01>
       ) 
     
   return
     $response
};