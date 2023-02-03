module namespace fuseki2 = 'http://garpix.com/semantik/app/fuseki2';

declare
  %public
function fuseki2:deleteGraph(
  $graphName as xs:string,
  $endPoint as xs:string
) as xs:string
{
  let $request := replace('DROP GRAPH  <%1>', '%1', $graphName)
  return
    fuseki2:update($request, $endPoint)
};

declare
  %public
function fuseki2:uploadGraph(
  $rdf as element(Q{http://www.w3.org/1999/02/22-rdf-syntax-ns#}RDF),
  $graphURI as xs:string,
  $endPoint as xs:string
)
{
  let $url :=
    web:create-url($endPoint || "/data", map{'graph':$graphURI})
  let $request :=
      <http:request method='POST'>
        <http:multipart media-type="multipart/form-data; boundary=----7MA4YWxkTrZu0gW">
            <http:header name="Content-Disposition" value='form-data; name="file"; filename="file.rdf"'/>
            <http:body media-type="application/rdf+xml">{$rdf}</http:body>           
        </http:multipart> 
      </http:request>   
  let $response := http:send-request($request, $url)
  return
     $response[1]/@status/data()
};

declare
  %private
function fuseki2:update(
  $query as xs:string,
  $endPoint as xs:string
) as xs:string
{
  let $request :=
    <http:request method='POST'> 
      <http:body media-type = "application/x-www-form-urlencoded"/>
    </http:request> 
  let $response := 
    http:send-request($request, $endPoint, 'update=' || $query)
  return
     $response[1]/@status/data()
};

declare
  %public
function fuseki2:get(
  $query as xs:string,
  $endPoint as xs:string
) as element(json)
{
  let $request :=
    <http:request method='POST'> 
      <http:body media-type = "application/x-www-form-urlencoded"/>
    </http:request> 
  let $response := 
    http:send-request($request, $endPoint, 'query=' || $query)
  return
     $response[2]/json
};