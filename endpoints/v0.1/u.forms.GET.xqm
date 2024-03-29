module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
    
import module namespace читатьФормы = 'http://iro37.ru/trac/core/data/dbRead.Forms'
  at '../../core/data/dbReadForms.xqm';

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
  %rest:path( '/trac/api/v0.1/u/forms' )
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
        for $i in request:parameter-names()
        where not( $i = $data:зарезервированныеПараметрsЗапроса )
        return map{ $i : request:parameter( $i ) }
      )
    
    let $data := 
      читатьФормы:формыПользователя(
        $userID, $s, $l, $xq, 
        map{ 'имяПеременойПараметров' : 'params', 'значенияПараметров' : $params }
      )
 
    let $result :=
      <forms
        starts = "{ $s }"
        limit = "{ $l }"
        total = "{ count( $data ) }"
        userID = "{ $userID }">
        { $data }
      </forms>
    
    let $params := 
      string-join(
          for $i in request:parameter-names()
          where not( $i = ( 'access_token', 'cache' ) )
          return $i || request:parameter( $i ) 
        )
    let $uri := session:get( 'userID' ) || $params || request:uri()
    let $hash :=  xs:string( xs:hexBinary( hash:md5( $uri ) ) )
    let $resPath := config:param( 'cache.dir' ) || $hash
    
    return
      (
        file:write( config:param( 'cache.dir' ) || $hash, $result ),
        $result
      )
};