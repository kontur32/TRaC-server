module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../../core/data/dbReadData.xqm';
  
import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at '../../../core/permissions/auth.xqm';
  
declare
  %updating
  %rest:DELETE
  %rest:query-param( 'id', '{ $id }' )
  %rest:query-param( 'instance', '{ $instance }' )
  %rest:query-param( 'access_token', '{ $access_token }' )
  %rest:path( '/trac/api/v0.1/u/data' )
function data:get( $id, $instance, $access_token )
{
  let $authorization := 
      if ( $access_token != "" )
      then( "Bearer " || $access_token )
      else ( request:header( "Authorization" ) )
  let $userID := auth:userID( $authorization )
  let $node :=
    читатьБД:всеДанныеПользователя( $userID )
    [ @status = 'active' ]
    [ @id = $id ]
    [ if( $instance != '' )then( @updated  = replace( $instance, ' ', '+' ) )else( true() ) ]
  
  return
    (
      for $i in $node
      return
        replace value of node  $i/@status with 'delete',
        update:output( <result>{ count( $node ) }</result> )
    )
};