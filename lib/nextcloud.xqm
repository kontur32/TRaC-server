module namespace nc = 'http://iro37.ru/trac/lib/nextCloud';

import module namespace nextCloud = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/nextCloud/'
  at 'C:\Program Files (x86)\BaseX\webapp\zapolniTitul\api\v2.1\functions\nextCloud.xqm';
  
import module namespace dav = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/dav/'
  at 'C:\Program Files (x86)\BaseX\webapp\zapolniTitul\api\v2.1\functions\webdav.xqm';

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../core/data/dbReadData.xqm';

declare function nc:getResource( $storeRecord, $tokenRecordsFilePath, $path  ){

  let $tokenRecords := fetch:xml( $tokenRecordsFilePath )//data
  
  let $fullDavPath :=
    $storeRecord/row/cell[@id ="http://dbx.iro37.ru/zapolnititul/признаки/путьРесурс"]/text()
    || '/' ||
    $storeRecord/row/cell[@id ="http://dbx.iro37.ru/zapolnititul/признаки/webdavEndpoint"]/text()
    || '/' ||
    $storeRecord/row/cell[@id ="http://dbx.iro37.ru/zapolnititul/признаки/владелецРесурса"]/text()
  
  let $token :=
    nextCloud:токен(
        $storeRecord/row,
        $tokenRecords,
        $tokenRecordsFilePath,
        $fullDavPath
      )
  let $rawData := 
      dav:получитьФайл( $token, iri-to-uri( $fullDavPath || '/' || $path )  )
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
};