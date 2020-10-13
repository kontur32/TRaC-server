module namespace templates = 'http://iro37.ru/trac/api/v0.1/u/templates';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';
  
import module namespace auth = "http://iro37.ru/trac/core/permissions/auth"
  at '../../core/permissions/auth.xqm';

declare
  %public
  %rest:method( 'GET' )
  %rest:query-param( 'starts', '{ $starts }' )
  %rest:query-param( 'limit', '{ $limit }' )
  %rest:query-param( 'xq', '{ $query }' )
  %rest:query-param( "access_token", "{ $access_token }", "" )
  %rest:path( '/trac/api/v0.1/u/data' )
function
  templates:get(
    $starts as xs:string*,
    $limit as xs:string*,
    $query,
    $access_token as xs:string*
  ){
    
    let $authorization := 
      if ( $access_token != "")
      then( "Bearer " || $access_token )
      else ( request:header( "Authorization" ) )
      
    let $userID := auth:userID( $authorization )
    
    let $xq :=
      if( $query )
      then(
        let $q := 
          if( matches( $query, '^http[s]{0,1}://' ) )
          then(
            fetch:text( $query )
          )
          else( $query )
        return
          if( try{ xquery:parse( $q ) } catch*{ false() } )
          then( $q )
          else( '.' )
      )
      else( '.' )
    
    let $s := 
      if( $starts )then( number( $starts ) )else( 1 )
    let $l := 
      if( $limit )then( number( $limit ) )else( 10 )
    let $result := 
      читатьБД:данныеПользователя( $userID, $s, $l, $xq, map{ 'query' : 'аева' } )
 
    return
      <data
        starts = "{ $s }"
        limit = "{ $result?количество }"
        total = "{ $result?общееКоличество }"
        userID = "{ $userID }">{
        $result?шаблоны
      }</data>
};