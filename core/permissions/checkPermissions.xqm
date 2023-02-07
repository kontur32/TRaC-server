module namespace check = "http://iro37.ru/trac/core/permissions/checkPermissions";

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at 'auth.xqm';

declare
  %rest:GET
  %rest:POST
  %rest:PUT
  %rest:DELETE
  %rest:form-param( "access_token", "{ $access_token_form }", "" )
  %rest:query-param( "access_token", "{ $access_token }", "" ) 
  %perm:check( '/trac/api/v0.2/u/', '{ $perm }' )
function check:check.v0.2( $perm, $access_token, $access_token_form ) {
  check:check( $perm, $access_token, $access_token_form )
};
 
declare
  %rest:GET
  %rest:POST
  %rest:PUT
  %rest:DELETE
  %rest:form-param( "access_token", "{ $access_token_form }", "" )
  %rest:query-param( "access_token", "{ $access_token }", "" ) 
  %perm:check( '/trac/api/v0.1/u/', '{ $perm }' )
function check:check( $perm, $access_token, $access_token_form ) {
  
  let $authorization := 
    if ( $access_token != ""  )
    then( "Bearer " || $access_token )
    else ( 
      if( $access_token_form != ""  )
      then( "Bearer " || $access_token_form)
      else( request:header( "Authorization" ) ) )
    
  return
    if( $authorization )
    then(
      let $tokenUserID := auth:userID( $authorization )
      return
        if( $tokenUserID )
        then( session:set( 'userID', $tokenUserID )) (: разрешает обращение :)
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

(: кэширование ответов :)

declare
  %rest:GET
  %perm:check( '/trac/api/v0.1/u/forms' )
function check:getForms(){
  check:getData()
};

declare
  %rest:GET
  %perm:check( '/trac/api/v0.1/u/data' )
function check:getData(){
  let $params := 
    string-join(
        for $i in request:parameter-names()
        where not( $i = ( 'access_token', 'cache' ) )
        return $i || request:parameter( $i ) 
      )
  let $uri := session:get( 'userID' ) || $params || request:uri()
  let $hash :=  xs:string( xs:hexBinary( hash:md5( $uri ) ) )
  let $resPath := config:param( 'cache.dir' ) || $hash
  where  request:parameter( 'cache' )
  where file:exists( $resPath )
  where 
    (
     current-dateTime() - file:last-modified( $resPath )
   ) div xs:dayTimeDuration('PT1S') < xs:integer( request:parameter( 'cache' ) )
  return
     doc( $resPath ) update insert node attribute {'mod'}{file:last-modified( $resPath )} into ./child::*
};