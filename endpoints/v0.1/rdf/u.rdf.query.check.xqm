module namespace check = 'http://iro37.ru/trac/api/v0.1/u/rdf/query/check';


declare
  %rest:GET
  %rest:query-param("query","{$query}")
  %rest:query-param("output","{$output}")
  %perm:check( '/trac/api/v0.1/u/rdf/query')
function check:rdf.query(
  $query as xs:string*,
  $output as xs:string*
) {
    if(empty($query))
    then(
      <rest:response><http:response status="400"/></rest:response>,
     'Не указан обязательный параметр query'
    )
    else(
      if(not(empty($output)) and not($output = ('json', 'xml')))
      then(
        <rest:response><http:response status="400"/></rest:response>,
       'Параметр output может быть: json (по умолчанию) или xml'
      )
    )
};