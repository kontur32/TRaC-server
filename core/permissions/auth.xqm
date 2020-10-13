module namespace auth = "http://iro37.ru/trac/core/permissions/auth";

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';

declare function auth:userID( $token )
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