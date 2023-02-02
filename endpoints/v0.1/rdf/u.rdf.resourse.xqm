module namespace rdf = 'http://iro37.ru/trac/api/v0.1/u/rdf/graph/post';

import module namespace conf = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../../core/utilits/config.xqm';

import module namespace graph = 'http://iro37.ru/trac/api/v0.1/u/rdf/graph'
 at 'u.rdf.graph.xqm';
 
import module namespace resource = 'http://iro37.ru/trac/api/v0.1/u/data/stores'
  at '../u.data.GET.resource.xqm';

(: преобразует TRCI в RDF/XML - публичный метод :)
declare 
  %rest:POST
  %output:method('xml')
  %rest:form-param("trci","{$trci}")
  %rest:form-param("schema","{$schema}")
  %rest:path("/trac/api/v0.1/p/rdf/trci2rdf")
  %private
function rdf:trci-to-rdf(
  $trci, $schema as xs:string
) 
{
  let $rawData :=
    if($trci instance of map(*))
    then(map:get($trci, map:keys($trci)[1]))
    else(xs:base64Binary($trci))
  let $request := 
      <http:request method='POST'>
        <http:header name="Content-type" value="multipart/form-data"/>
          <http:multipart media-type = "multipart/form-data" >
              <http:header name='Content-Disposition' value='form-data; name="trci"'/>
              <http:body media-type = "application/octet-stream">{$rawData}</http:body>
              <http:header name='Content-Disposition' value='form-data; name="schema"'/>
              <http:body media-type = "text/plain">{$schema}</http:body>
          </http:multipart> 
        </http:request>
  let $response := 
    http:send-request($request, conf:param('semantic.factory'))
  return
   $response[2]/Q{http://www.w3.org/1999/02/22-rdf-syntax-ns#}RDF
};

(: загружает ресурс в RDF-хранилище :)
declare
  %public
  %rest:POST
  %rest:form-param('path', '{$path}')
  %rest:form-param('schema', '{$schema}')
  %rest:path('/trac/api/v0.1/u/rdf/stores/{$storeID}')
function rdf:upload(
  $path as xs:string*,
  $schema as xs:string*,
  $storeID as xs:string
)
{
   let $trci := resource:get($path, '.', $storeID, ())//table[1]
   let $rdf :=
     rdf:trci-to-rdf(
       convert:string-to-base64(serialize($trci)),
       $schema
     )
   let $graphURI :=
     graph:datasetName()||'/store/'||$storeID||'/'||$path
   return
     graph:uploadGraph(
       $graphURI,
       map{'file':convert:string-to-base64(serialize($rdf))}
     )
};