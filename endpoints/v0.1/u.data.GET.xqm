module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
    
import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../core/data/dbReadData.xqm';

declare variable 
  $data:зарезервированныеПараметрsЗапроса := ('xq', 'starts', 'limit');

declare
  %public
  %rest:GET
  %rest:query-param('starts', '{$starts}')
  %rest:query-param('limit', '{$limit}')
  %rest:query-param('xq', '{$query}')
  %rest:path( '/trac/api/v0.1/u/data' )
function
  data:get(
    $starts as xs:string*,
    $limit as xs:string*,
    $query
  ){
    let $userID := session:get('userID')
    let $xq :=
      if($query)
      then(
        let $q := 
          if(matches($query, '^http[s]{0,1}://'))
          then(fetch:text($query))
          else($query)
        return
          if(try{xquery:parse($q)}catch*{false()})
          then($q)
          else('.')
      )
      else('.')
    
    let $s := if($starts)then(number($starts))else(1)
    let $l := if($limit)then(number($limit))else(10)
    
    let $params := 
      map:merge(
          for $i in request:parameter-names()
          where not( $i = $data:зарезервированныеПараметрsЗапроса )
          return map{ $i : request:parameter( $i ) }
      )
    
    let $data := 
      читатьБД:данныеПользователя(
        $userID, $s, $l, $xq, 
        map{ 'имяПеременойПараметров' : 'params', 'значенияПараметров' : $params }
      )
 
    let $result :=
      <data
        starts="{$s}"
        limit="{$l}"
        total="{count($data?шаблоны)}"
        userID="{$userID}">{
        $data?шаблоны
      }</data>
    return
      $result
};