(:
  функции для преобразования TRCI в RDF-штрих
:)

module namespace trciToRdf = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/trciToRdf/';

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace о = 'http://dbx.iro37.ru/отнтология/';
declare namespace с = 'http://dbx.iro37.ru/сущности/';
declare namespace п = 'http://dbx.iro37.ru/признаки/';

(: преобразует TRCI в RDF 'с:токенДоступаOAuth2' :)

declare function trciToRdf:tokenData( $tokenData as element( table )* ){
  element { xs:QName( 'rdf:Description' ) }{
    attribute { 'about' } { $tokenData//row/@id/data() },
    for $i in $tokenData//cell
    return
      element { xs:QName( 'п:' || $i/@id/data() ) } { $i/text() } 
  }
};

declare 
  %private
function
  trciToRdf:transform(
    $data as element( row ),
    $type as xs:string
 ){
 element { xs:QName( 'rdf:Description' ) }{
    attribute { 'about' } { $data/@id/data() },
    attribute { 'type' } { $type },
    for $i in $data/cell
    let $признак :=
      replace( tokenize( $i/@id/data(), '/' )[ last() ], ' ', '-' )
    return
      element { xs:QName( 'п:' || $признак ) } { $i/text() },
    element { 'п:userID' } {  $data/@userID/data() }
  }
};

declare
  %public
function trciToRdf:storeData( $storeData as element( row ) ){
  trciToRdf:transform( $storeData, 'o:хранилищеNextcloud' )
};

declare
  %public
function trciToRdf:sourceData( $sourceData as element( row ) ){
  trciToRdf:transform( $sourceData, 'o:ресурсNextcloud' )
};
