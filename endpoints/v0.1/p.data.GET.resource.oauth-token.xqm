module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data/stores/nextCloudOAuth2s';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';

import module namespace dav = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/dav/'
  at '../../lib/nextCloud/webdav.xqm';

import module namespace getData = 'http://iro37.ru/trac/api/v0.1/u/data/stores'
  at  'u.data.GET.resource.xqm';

import module namespace localStore = 'http://iro37.ru/trac/lib/localStore'
  at '../../lib/localStore.xqm';

declare
  %public
  %rest:method('GET')
  %output:method('xml')
  %rest:query-param('path', '{$path}')
  %rest:path('/trac/api/v0.1/u/data/stores/nextcloud/{$storeID}/file/trci')
function data:getFromNextCloud(
  $storeID as xs:string,
  $path as xs:string
){
  let $storeRecord :=
    читатьБД:данныеПользователя(
      session:get('userID'), 1, 1,
      replace('.[row[ends-with(@id, "%1")]]', '%1', $storeID)
    )?шаблоны/row
  
  let $tokenRecord := 
    let $hash := $storeID || ':oauth2_token'
    let $currentTokenRecord := localStore:readFromStore($hash)      
    let $updated := $currentTokenRecord/@updated/data()
    let $expires := $currentTokenRecord//expires__in/number()
    let $expiresDayTime := 
       xs:dateTime($updated) + xs:dayTimeDuration('PT' || $expires - 10 || 'S' )
    return
     if($expiresDayTime > current-dateTime())
     then($currentTokenRecord)
     else(
       let $newTokenRecord :=
         data:refreshAccessToken($currentTokenRecord, $storeRecord)
       return
       (
         $newTokenRecord,
         localStore:saveToStore(localStore:buildRecord($newTokenRecord, $hash))
       )
     )
  
  let $davPath := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/root_path"]/text() || '/remote.php/dav/files/'
  let $storePath :=
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/локальныйПуть"]/text()
  let $userLoginInStore := $tokenRecord//user__id/text()
  let $fullDavFilePath := 
    $davPath || $userLoginInStore || '/' || $storePath || '/' || $path
  let $accessToken := $tokenRecord//access__token/text()
  return
      (dav:получитьФайл($accessToken, $fullDavFilePath))
};

declare
  %private
function data:refreshAccessToken($tokenRecord, $storeRecord){
  let $token_path := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/oauth2_token_path"]/text()
  let $client_id := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/client_id"]/text()
  let $client_secret := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/client_secret"]/text()
  let $refresh_url :=
    web:create-url(
      $token_path,
      map{
        'client_id':$client_id,
        'client_secret':$client_secret,
        'grant_type':'refresh_token',
        'refresh_token':$tokenRecord//refresh__token/text()
      }
    )
  let $result :=
    http:send-request(
      <http:request method='POST' href='{iri-to-uri($refresh_url)}'/>
    )
  return
   $result[2]
};
    
declare
  %private
  %rest:method('GET')
  %rest:query-param('state', '{$state}')
  %rest:query-param('code', '{$code}')
  %output:method('text')
  %rest:path('/trac/api/v0.1/p/data/stores/oauth2/token')
function data:get($state as xs:string, $code as xs:string*){
  let $storeID := substring-before($state, ':')
  let $userID := substring-after($state, ':')
  let $storeRecord :=
    читатьБД:данныеПользователя(
      $userID, 
      1, 
      10,
      replace('.[row[ends-with(@id, "%1")]]', '%1', $storeID)
    )?шаблоны/row[1]
  
  let $authorize_path := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/oauth2_authorize_path"]/text()
  let $token_path := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/oauth2_token_path"]/text()
  let $client_id := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/client_id"]/text()
  let $client_secret := 
    $storeRecord/cell[@id="http://dbx.iro37.ru/zapolnititul/признаки/client_secret"]/text()
  return
    if(empty($code))
    then(
      web:create-url(
       $authorize_path,
       map{'response_type':'code', 'client_id':$client_id, 'state':$state}
      )
    )
    else(
      let $href := 
        web:create-url(
          $token_path,
          map{
            'client_id':$client_id,
            'client_secret':$client_secret,
            'grant_type':'authorization_code',
            'code':$code
          }
        )
      let $result := 
        http:send-request(
          <http:request method='POST' href='{iri-to-uri($href)}'/>
        )
      return
        if($result[1]/@status/data()!="400")
        then(
          'OK',
          localStore:saveToStore(
            localStore:buildRecord($result[2], $storeID || ':oauth2_token')
          )
        )
        else(<err:ошибка_получения_токена/>)
    )
};