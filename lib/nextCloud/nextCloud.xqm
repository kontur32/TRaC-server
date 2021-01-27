(:
  функции работы с ресурсами NextCloud
:)

module namespace nextCloud = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/nextCloud/';

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare namespace iro = "http://dbx.iro37.ru/";
declare namespace с = 'http://dbx.iro37.ru/сущности/';
declare namespace п = 'http://dbx.iro37.ru/признаки/';

declare namespace d="DAV:";

import module namespace dav = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/dav/'
  at 'webdav.xqm';
  
import module namespace oauth2 = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/oauth2/'
  at 'oauth2.xqm';
  
import module namespace trciToRdf = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/trciToRdf/'
  at 'trciToRdf.xqm';  
 
 (: в браузере
   https://roz37.ru/unoi/index.php/apps/oauth2/authorize?response_type=code&client_id=3dAc51T87qeU0xzAPkIf4AjduUkDBHXts1Ujeq8TaW9MRUr1cCuEsIox8zpehPUp
 :)

declare
  %private
function nextCloud:сохранитьЗаписьТокена( $path, $tokenRecord ){
  let $tokenRecords := fetch:xml( $path )/data
  let $storeID := $tokenRecord/row/cell[ @id = 'storeID' ]/text()
  return
    file:write(
      $path,
      if(
         $tokenRecords/table[ row/cell[ @id = 'storeID' ]/text() = $storeID ]
      )
      then(
        $tokenRecords update 
        replace node ./table[ row/cell[ @id = 'storeID' ]/text() = $storeID ] 
        with $tokenRecord
      )
      else(
        $tokenRecords update insert node $tokenRecord into  .
      )
    )
};

declare function nextCloud:полныйПутьDAV( $storeRecord ){
  let $storeData := trciToRdf:storeData( $storeRecord )
  return
    string-join(
      (
        $storeData/п:путьРесурс,
        $storeData/п:webdavEndpoint,
        $storeData/п:владелецРесурса
      ),
      '/'
    )
};

declare 
  %public
function
  nextCloud:токен(
    $storeRecord,
    $tokenRecords as element( data )*,
    $tokenRecordsFilePath,
    $fullDavPath
  ) as xs:string {
  let $storeData := trciToRdf:storeData( $storeRecord )
  let $tokenData := 
    trciToRdf:tokenData( 
      $tokenRecords/table[ row[ cell[ @id = 'storeID'] = $storeData/п:id ] ]
    )
    
  let $tokenEndPoint :=
    string-join( ( $storeData/п:путьРесурс, $storeData/п:tokenEndpoint ), '/' )
  
  let $params := oauth2:buildParams( $storeData, $tokenData )
  let $result := oauth2:получитьТокен( $params, $tokenEndPoint, $fullDavPath )
  
  return
   if( $result?status = 'valid' )
   then( $result?token?access_token ) 
   else(
     if( $result?status = ( 'refresh', 'new' ) and not( $result?token?error ) )
     then(
       let $записьДляСохранения := 
         oauth2:генерацияЗаписиТокенаДляСохранения( $result )
       return
         nextCloud:сохранитьЗаписьТокена(
           $tokenRecordsFilePath,
           $записьДляСохранения
         ),
        $result?token?access_token 
     )
     else(
         <err:OAUTH2-00>
           Не удалось получить токен: { $result?token?error }
         </err:OAUTH2-00>
     )
   )
};

declare function nextCloud:получитьВсеФайлыИзПапки( $token, $fullDavPath ){
  let $filePath := 
  dav:получитьСвойстваПапки( $token, $fullDavPath || '/УНОИ/Кафедры/Естественно-научных дисциплин' )[ 2 ]
  return
    for $i in $filePath//d:response[ not( d:propstat/d:prop/d:resourcetype/d:collection ) and d:href/text() ]/d:href/text()
    let $file := dav:получитьФайл( $token, 'https://roz37.ru' || $i )
    let $fileName := web:decode-url( $i )
    return
         map{ $fileName : $file }
};

declare 
  %public
function nextCloud:получитьРесурс(
    $resourceRecord as element( rdf:Description ),
    $storeRecord as element( row ),
    $tokenRecordsFilePath as xs:string
  ){
  
  let $tokenRecords := fetch:xml( $tokenRecordsFilePath )//data
  
  let $полныйПутьDAV := nextCloud:полныйПутьDAV( $storeRecord )
  
  let $token := 
    nextCloud:токен(
      $storeRecord,
      $tokenRecords,
      $tokenRecordsFilePath,
      $полныйПутьDAV
    )
  
  return
    if( $token instance of element( err ) )
    then( $token )
    else(
      
      let $путьФайла :=  $resourceRecord/п:локальныйПуть/text()
      let $source := dav:получитьФайл( $token, $полныйПутьDAV || '/' || $путьФайла   )
      return
         $source
    )
};

declare function nextCloud:получитьФайл( $storeRecord, $tokenRecordsFilePath, $path  ){

  let $tokenRecords := fetch:xml( $tokenRecordsFilePath )//data
  
  let $fullDavPath := nextCloud:полныйПутьDAV( $storeRecord/row )
  
  let $token :=
    nextCloud:токен(
        $storeRecord/row,
        $tokenRecords,
        $tokenRecordsFilePath,
        $fullDavPath
      )
  let $rawData := 
      dav:получитьФайл( $token, iri-to-uri( $fullDavPath || '/' || $path )  )
  return
    $rawData
};