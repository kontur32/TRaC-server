module namespace check = "'http://iro37.ru/trac/core/permissions/checkPermissions";

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';

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
  let $tokenUserID := check:userID( $authorization )
  
  return
    if( $authorization )
    then(
      if( $requestUserID = $tokenUserID )
      then( ) (: разрешает обращение :)
      else(
        <rest:response>
          <http:response status="403" message="Forbidden"/>
        </rest:response>,
        <error>Ошибка: пользователю с индентификатором "{ $tokenUserID }" доступ запрещен</error>
      )
    )
    else(
      <rest:response>
        <http:response status="401" message="Unauthorized">
          <http:header name="WWW-Authenticate" value="Required bearer token"/>
        </http:response>
      </rest:response>,
      <error>Ошибка: запрос без авторизации</error>
    )
};

declare function check:userID( $token )
{
  let $request := 
  <http:request method='get'>
    <http:header name="Authorization" value= '{ $token }' />
  </http:request>
  
  let $response := 
      http:send-request(
        $request,
        config:param( "JWTendpoit" ) || "/wp-json/wp/v2/users/me?context=edit"
    )
    return
      $response[ 2 ]/json/id/text()
};