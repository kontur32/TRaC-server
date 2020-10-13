module namespace check = "http://iro37.ru/trac/core/permissions/checkPermissions";

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at 'auth.xqm';
 
declare
  %rest:query-param( "access_token", "{ $access_token }", "" ) 
  %perm:check( '/trac/api/v0.1/u/', '{ $perm }' )
function check:check( $perm, $access_token ) {
  
  let $authorization := 
    if ( $access_token != "")
    then( "Bearer " || $access_token )
    else ( request:header( "Authorization" ) )
    
  let $requestUserID := 
    substring-before(
      substring-after( $perm?path, '/trac/api/v0.1/u/' ),
      "/"
    )
  
  return
    if( $authorization )
    then(
      let $tokenUserID := auth:userID( $authorization )
      return
        if( $tokenUserID )
        then( ) (: разрешает обращение :)
        else(
          <rest:response>
            <http:response status="403" message="Forbidden"/>
          </rest:response>,
          <err:AUTH02>Ошибка: неудачная попытка авторизации</err:AUTH02>
        )
    )
    else(
      <rest:response>
        <http:response status="401" message="Unauthorized">
          <http:header name="WWW-Authenticate" value="Required bearer token"/>
        </http:response>
      </rest:response>,
      <err:AUTH01>Ошибка: запрос без авторизации</err:AUTH01>
    )
};