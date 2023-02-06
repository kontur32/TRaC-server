module namespace rdf = 'http://iro37.ru/trac/api/v0.1/u/rdf/query';

import module namespace graph = 'http://iro37.ru/trac/api/v0.1/u/rdf/graph'
  at 'u.rdf.graph.xqm';

declare 
  %rest:GET
  %rest:query-param("query","{$query}", "")
  %rest:query-param("output","{$output}", 'json')
  %rest:path("/trac/api/v0.1/u/rdf/query")
  %private
function rdf:query(
  $query as xs:string,
  $output as xs:string
)
{
    let $datasetEndpoint := graph:datasetEndpoint()
    let $result := rdf:sendSPARQL($query, $output, $datasetEndpoint)
    return
      rdf:reponse($output, $result)
};

declare
  %private
function rdf:reponse($output as xs:string, $result as xs:string)
{
  let $params :=
    switch ($output)
    case 'xml' return ['application/xml',  parse-xml($result)]
    case 'json' return ['application/json', $result]
    default return ['application/json', $result]
  let $mime := $params?1 || "; charset=utf-8"
  return
   (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Type" value="{$mime}"/>
        </http:response>
      </rest:response>,
      $params?2
    )
};

declare
  %private
function rdf:sendSPARQL(
  $query as xs:string,
  $output as xs:string,
  $endPoint as xs:string
) as xs:string
{
  let $request :=
    web:create-url(
      $endPoint,
      map{
        "query": $query,
        "output" : $output
      }
    )  
  return
    fetch:text($request)
};