module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';

declare
  %public
  %rest:method('GET')
  %output:method('text')
  %rest:query-param('path', '{$path}')
  %rest:path('/trac/api/v0.1/p/data/stores/nextcloud/{$storeID}')
function data:getFromNextCloud($storeID as xs:string, $path as xs:string*){
  let $storeRecord :=
    читатьБД:данныеПользователя(
      '220', 
      1, 
      10,
      replace('.[row[ends-with(@id, "%1")]]', '%1', $storeID)
    )?шаблоны/row[1]
  
  let $tokenRecord :=
    db:open('titul24', 'store')/store/table[starts-with(@id, $storeID)][last()]
  
  let $updated := $tokenRecord/@updated/data()
  let $expires := $tokenRecord//expires__in/number()
  let $expiresDayTime := 
     xs:dateTime($updated) + xs:dayTimeDuration('PT' || $expires - 10 || 'S' )
  return
   if($expiresDayTime > current-dateTime())
   then(
     $tokenRecord//access__token/text()
   )
   else(
     data:refreshAccessToken($tokenRecord, $storeRecord)
   )
};

declare function data:refreshAccessToken($tokenRecord, $storeRecord){
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
  return
    http:send-request(
      <http:request method='POST'
         href='{iri-to-uri($refresh_url)}'/>
    )
};
    
declare
  %private
  %updating
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
  let $tokenRecord := data:tokenRecord($storeID)
  return
    if(empty($code))
    then(
      update:output(
        web:create-url(
           $authorize_path,
           map{'response_type':'code', 'client_id':$client_id, 'state':$state}
         )
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
          update:output('OK'),
          data:saveToStore($storeID || ':oauth2_token', $result[2])
        )
        else(update:output(<err:ошибка_получения_токена/>))
    )
};

declare 
function data:tokenRecord($storeID){ 
    db:open('titul24', 'store')
    /store/table[@id/data()=$storeID || ':oauth2_token'][last()]
};

declare 
  %updating
function data:saveToStore($hash, $record){
  let $db := 
    db:open('titul24', 'store')/store
  let $rec := <table id="{$hash}" updated="{current-dateTime()}">{$record}</table>
  return
    if($db/table/@id/data() = $hash)
    then(replace node $db/table[@id/data()=$hash][last()] with $rec)
    else(insert node $rec into $db)
};
  