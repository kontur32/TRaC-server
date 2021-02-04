module namespace search = "http://iro37.ru/trac/api/v0.1/u/data/search/patient";

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../../core/utilits/config.xqm';

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
    db:attribute( $config:params?имяБазыДанных, 'https://schema.org/familyName', 'id' )
    /parent::*[ matches( lower-case( . ), lower-case( $term ) ) ]
    /parent::*[ @type="https://schema.org/Patient"]
    /parent::*[ @status = "active" and @userID = $userID ]

  let $ii := 
    for $i in $data
    let $a := $i/row/@id
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