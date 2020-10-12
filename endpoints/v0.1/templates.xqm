module namespace templates = 'http://iro37.ru/trac/api/v0.1/templates';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead'
  at '../../core/data/dbRead.xqm';

declare
  %private
  %rest:method( 'GET' )
  %rest:query-param( 'starts', '{ $starts }' )
  %rest:query-param( 'limit', '{ $limit }' )
  %rest:path( '/trac/api/v0.1/u/{ $userID }/templates' )
function
  templates:get(
    $userID as xs:string,
    $starts as xs:string*,
    $limit as xs:string*
  ){
    
    let $s := 
      if( $starts )then( number( $starts ) )else( 1 )
    let $l := 
      if( $limit )then( number( $limit ) )else( 10 )
    let $result := 
      читатьБД:шаблоныПользователя( $userID, $s, $l )
      
    return
      <templates starts = "{ $s }" limit = "{ $l >= count( $result ) ?? count( $result ) !! $l }">{
        $result
      }</templates>
};