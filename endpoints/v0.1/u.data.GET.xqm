module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';
  
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';

import module namespace store = 'http://iro37.ru/trac/api/v0.1/u/data/stores'
  at 'u.data.GET.resource.xqm';

declare variable 
  $data:зарезервированныеПараметрsЗапроса := 
    ( 'access_token', 'xq', 'starts', 'limit' );

declare
  %public
  %rest:method( 'GET' )
  %rest:query-param( 'starts', '{ $starts }' )
  %rest:query-param( 'limit', '{ $limit }' )
  %rest:query-param( 'xq', '{ $query }' )
  %rest:query-param( "access_token", "{ $access_token }", "" )
  %rest:path( '/trac/api/v0.1/u/data' )
function
  data:get(
    $starts as xs:string*,
    $limit as xs:string*,
    $query,
    $access_token as xs:string*
  ){
    let $userID := session:get( 'userID' )
    let $xq :=
      if( $query )
      then(
        let $q := 
          if( matches( $query, '^http[s]{0,1}://' ) )
          then( fetch:text( $query ) )
          else( $query )
        return
          if( try{ xquery:parse( $q ) } catch*{ false() } )
          then( $q )
          else( '()' )
      )
      else( '.' )
    
    let $s := if( $starts )then( number( $starts ) )else( 1 )
    let $l := if( $limit )then( number( $limit ) )else( 10 )
    
    let $params := 
      map:merge(
        (
          for $i in request:parameter-names()
          where not( $i = $data:зарезервированныеПараметрsЗапроса )
          return map{ $i : request:parameter( $i ) },
          map{
            '_api' : map{ 'getTrci' : function( $s, $p, $q ){ store:xlsx-to-trci( $s, $p, $q ) } }
          }
        )
      )
    
    let $result := 
      читатьБД:данныеПользователя(
        $userID, $s, $l, $xq, 
        map{ 'имяПеременойПараметров' : 'params', 'значенияПараметров' : $params }
      )
 
    return
      <data
        starts = "{ $s }"
        limit = "{ $result?количество }"
        total = "{ count( $result?шаблоны ) }"
        userID = "{ $userID }">{
        $result?шаблоны
      }</data>
};