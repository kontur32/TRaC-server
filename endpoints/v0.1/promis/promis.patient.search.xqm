module namespace search = "http://iro37.ru/trac/api/v0.1/u/data/search/patient";

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data'
  at '../../../core/data/dbReadData.xqm';

(: функция для аякс-поиска :)
declare 
  %rest:query-param('term', '{ $term }')
  %rest:path('/trac/api/v0.1/p/data/{ $userID }/search.patient')
  %output:method('json')
function search:main ( $userID, $term ){
  search:getData( $userID, $term )
};

declare function search:getData( $userID, $term ){
  let $data :=
    db:attribute( 'titul24', 'https://schema.org/familyName', 'id' )
    /parent::*[ matches( lower-case( . ), lower-case( $term ) ) ]
    /parent::*[ @type="https://schema.org/Patient"]
    /parent::*[ @status = "active" and @userID = $userID ]

  let $ii := 
    for $i in $data
    let $a := $i/@id
    group by $a
    return 
      $i[ last() ]
  
  let $res :=
    for $i in $ii[ position() <= 10 ]
      let $birthDate := 
       replace(
         $i/row/cell[@id='https://schema.org/birthDate'],
         '(\d{4})-(\d{2})-(\d{2})',
         '$3.$2.$1'
       )
     return
       <_ type="object">
         <label>{
             $i/row/cell[@id='https://schema.org/familyName'] || ' ' ||
             $i/row/cell[@id='https://schema.org/givenName'] || ' ' ||
             $i/row/cell[@id='https://schema.org/additionalName'] || ' ' ||
             $birthDate
           }</label>
         <id>{ $i/row/substring-after( @id/data(), '#' ) }</id>
       </_ >
       
  return
    <json type="array">{ $res }</json>
};

declare function search:getData2( $userID, $term ){
  let $data := 
    читатьБД:данныеПользователя(
    $userID, 1, 0, ".",
    map{ 'имяПеременойПараметров' : 'params', 'значенияПараметров' : map{} }
  )

let $d := 
  $data?шаблоны
    [ @templateID = 'ad52a99b-2153-4a3f-8327-b23810fb38e4']
    [ matches( lower-case( row/cell[@id="https://schema.org/familyName"]/text() ), lower-case( $term ) ) ]
let $res :=  
 for $i in $d
 let $name := $i/row/cell[@id='https://schema.org/familyName']/text()
 
 let $birthDate := 
   replace(
     $i/row/cell[@id='https://schema.org/birthDate'],
     '(\d{4})-(\d{2})-(\d{2})',
     '$3.$2.$1'
   )
   
 return
   <_ type="object">
     <label>{
         $i/row/cell[@id='https://schema.org/familyName'] || ' ' ||
         $i/row/cell[@id='https://schema.org/givenName'] || ' ' ||
         $i/row/cell[@id='https://schema.org/additionalName'] || ' ' ||
         $birthDate
       }</label>
     <id>{ $i/row/substring-after( @id/data(), '#' ) }</id>
   </_ >
      
return
  <json type="array">{ $res }</json>
};