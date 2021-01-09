module namespace yandex = 'http://iro37.ru/trac/lib/yandex';

declare function yandex:getResource( $storeRecord, $path ){    
    let $token := 
      $storeRecord/row/cell[ @id = "http://dbx.iro37.ru/zapolnititul/сущности/токенДоступа" ]/text()
    let $storePath :=
      $storeRecord/row/cell[ @id = "http://dbx.iro37.ru/zapolnititul/признаки/локальныйПуть" ]/text()
      
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