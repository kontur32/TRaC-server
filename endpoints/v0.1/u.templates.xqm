module namespace templates = 'http://iro37.ru/trac/api/v0.1/u/templates';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead'
  at '../../core/data/dbReadTemplates.xqm';

import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at '../../core/permissions/auth.xqm';
  
declare
  %public
  %rest:method( 'GET' )
  %rest:query-param( 'starts', '{ $starts }' )
  %rest:query-param( 'limit', '{ $limit }' )
  %rest:query-param( "access_token", "{ $access_token }", "" )
  %rest:path( '/trac/api/v0.1/u/templates' )
function
  templates:get(
    $starts as xs:string*,
    $limit as xs:string*,
    $access_token as xs:string*
  ){
    let $authorization := 
      if ( $access_token != "")
      then( "Bearer " || $access_token )
      else ( request:header( "Authorization" ) )
      
    let $userID := auth:userID( $authorization )
    
    let $s := 
      if( $starts )then( number( $starts ) )else( 1 )
    let $l := 
      if( $limit )then( number( $limit ) )else( 10 )
    let $result := 
      читатьБД:шаблоныПользователя( $userID, $s, $l )
      
    return
      <templates
        starts = "{ $s }"
        limit = "{ $result?количество }"
        total = "{ $result?общееКоличество }"
        userID = "{ $userID }">{
        $result?шаблоны
      }</templates>
};