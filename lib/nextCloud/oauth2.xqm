(:
  функции для проверки, обновления и получения токена доступа по OAuth2
:)

module namespace oauth2 = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/oauth2/';

declare namespace с = 'http://dbx.iro37.ru/сущности/';
declare namespace п = 'http://dbx.iro37.ru/признаки/';

import module namespace dav = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/dav/'
  at 'webdav.xqm';

declare function oauth2:проверитьТокен( $access_token, $fullDavPath ){
  dav:получитьСвойстваПапки( $access_token, $fullDavPath )
    [ 1 ]/@status/substring( data(), 1, 1 ) = '2' ?? true() !! false()
};

declare function oauth2:запроситьТокен( $params as map(*), $tokenRequestEndpoint ){
  let $href := web:create-url( $tokenRequestEndpoint, $params )
  let $response:= 
      http:send-request(
          <http:request method='POST'
             href= '{ iri-to-uri( $href ) }' >
          </http:request>
        )
 return
   if( $response[ 1 ]/@status = '200' )
   then(
     let $expires_in := $response[ 2 ]/json/expires__in/text()
     let $expiration_dateTime := 
       current-dateTime() + xs:dayTimeDuration( replace( 'PT-S', '-',  $expires_in ) )
     return
       map{
         'access_token' : $response[ 2 ]/json/access__token/text(),
         'refresh_token' : $response[ 2 ]/json/refresh__token/text(),
         'expires_in' :  $expires_in,
         'expiration_dateTime' : $expiration_dateTime
       }
   )
   else(
     map{
       'error' : 'попробуйте обновить код доступа по адресу ' ||
       web:create-url(
         'https://roz37.ru/unoi/index.php/apps/oauth2/authorize',
         map{
           'response_type' : 'code',
           'client_id' : $params?client_id
         }
       )
     }
   )
};

declare
  %public
function oauth2:получитьТокен( $params as map(*), $tokenEndPoint, $fullDavPath ){
  if( $params?access_token and  oauth2:проверитьТокен( $params?access_token, $fullDavPath ) )
  then(
    map{
      'status' : 'valid',
      'token' : map{ 'access_token' : $params?access_token }
    }
  )
  else(
    let $refresh := oauth2:refreshToken( $params, $tokenEndPoint )
    return
      if( $refresh?refresh_token )
      then(
        map{
          'status' : 'refresh',
          'token' : $refresh,
          'storeID' : $params?storeID,
          'userID' : $params?userID
        }
      )
      else(
        map{
          'status' : 'new',
          'token' : oauth2:authorizationCode( $params, $tokenEndPoint ),
          'storeID' : $params?storeID,
          'userID' : $params?userID
        }
      )
  )
};

declare 
  %public
function oauth2:authorizationCode( $params, $tokenEndPoint ){
  let $p := 
      map{
        'grant_type' : 'authorization_code',
        'client_id' : $params?client_id,
        'client_secret' : $params?client_secret,
        'code' : $params?code
      }
    return
      oauth2:запроситьТокен( $p, $tokenEndPoint )
};

declare 
  %private
function oauth2:refreshToken( $params, $tokenEndPoint ){
  let $p := 
      map{
        'grant_type' : 'refresh_token',
        'client_id' : $params?client_id,
        'client_secret' : $params?client_secret,
        'refresh_token' : $params?refresh_token
      }
    return
      oauth2:запроситьТокен( $p, $tokenEndPoint )
};

declare
  %public
function oauth2:генерацияЗаписиТокенаДляСохранения( $params ){
  <table id="{ random:uuid() }" aboutType="http://dbx.iro37.ru/zapolnititul/Онтология/токенДоступаOAuth2" userID="{ $params?userID }" status="active" updated="{ current-dateTime() }">
    <row id = '{ "http://dbx.iro37.ru/zapolnititul/сущности/токенДоступаOAuth2#" || random:uuid() }'>
      <cell id = 'storeID'>{ $params?storeID }</cell>
      <cell id = "refresh_token">{ $params?token?refresh_token }</cell>
      <cell id = "access_token">{ $params?token?access_token }</cell>
      <cell id = "expiration_dateTime">{ $params?token?expiration_dateTime }</cell>
    </row>
  </table>
};

(: формирует набор параметров для получения токена :)

declare function oauth2:buildParams( $storeData, $tokenData ){
  map{
    'client_id' : $storeData/п:client_id/text(),
    'client_secret' : $storeData/п:client_secret/text(),
    'code' : $storeData/п:кодДляЗапросаТокенаДоступа/text(),
    'storeID' : $storeData/п:id/text(),
    'userID' : $storeData/п:userID/text(),
    
    'refresh_token' : $tokenData/п:refresh_token/text(),
    'access_token' : $tokenData/п:access_token/text()
  }   
};