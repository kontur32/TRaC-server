module namespace rdf = 'http://iro37.ru/trac/api/v0.1/u/rdf/graph/post';
  
declare 
  %rest:GET
  %output:method('xml')
  %rest:query-param("query","{$query}")
  %rest:query-param("output","{$output}", 'json')
  %rest:path("/trac/api/v0.1/u/rdf/query")
  %private
function rdf:trci-to-rdf(
  $query, $output as xs:string
)
{
  rdf:getData($query, $output)
};

declare function rdf:getData($q){rdf:getData($q, 'json')};

declare function rdf:getData($q, $m){
  let $e := 'http://ovz2.j40045666.px7zm.vps.myjino.ru:49408/portal.titul24.ru:'
  let $u := session:get('userID')
  return
    rdf:getData($q, $m, $e, $u)
};
declare function rdf:getData($q, $m, $e, $u){
  rdf:sendSPARQL($q, $m, $e || $u)
};

declare
  %public
function rdf:sendSPARQL(
  $query as xs:string,
  $форматСериализацииДанных as xs:string,
  $endPoint as xs:string
) as element()*{
  let $request :=
    web:create-url(
      $endPoint,
      map{
        "query": $query,
        "output" : $форматСериализацииДанных
      }
    )  
  return
    if($query!="")
    then(
      switch ($форматСериализацииДанных)
      case 'xml' return fetch:xml($request)//*:result
      case 'json' return json:doc($request)//results//_
      default return fetch:xml($request)//*:result
    )
    else()
};