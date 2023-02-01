module namespace templates = 'http://iro37.ru/trac/api/v0.1/p/templates';

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead'
  at '../../core/data/dbReadTemplates.xqm';
  
declare
  %private
  %rest:GET
  %rest:query-param( 'starts', '{ $starts }' )
  %rest:query-param( 'limit', '{ $limit }' )
  %rest:path( '/trac/api/v0.1/p/templates' )
function
  templates:get(
    $starts as xs:string*,
    $limit as xs:string*
  ){
     let $s := 
      if( $starts )then( number( $starts ) )else( 1 )
    let $l := 
      if( $limit )then( number( $limit ) )else( 10 )
    let $result := 
      читатьБД:шаблоны( $s, $l )
      
    return
       <templates
        starts = "{ $s }"
        limit = "{ $result?количество }"
        total = "{ $result?общееКоличество }">{
        $result?шаблоны
      }</templates>
};