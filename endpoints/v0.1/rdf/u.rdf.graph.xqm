module namespace graph = 'http://iro37.ru/trac/api/v0.1/u/rdf/graph';

import module namespace conf = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../../core/utilits/config.xqm';

import module namespace fuseki2 = 'http://garpix.com/semantik/app/fuseki2' 
  at '../../../lib/client.fuseki2.xqm';

import module namespace r = 'http://iro37.ru/trac/api/v0.1/u/rdf/dataset'
  at 'u.rdf.dataset.xqm';

(: генерирует URL датасета :)
declare function graph:datasetEndpoint(){
  conf:param('rdfEndpoint') ||  graph:datasetName()
};

declare function graph:datasetName(){
  conf:param('authDomain') || ':' || session:get('userID')
};

(:  публикует RDF-ресурс в графе датесета пользователя :)
declare 
  %rest:POST
  %rest:form-param("graphURI","{$graphURI}", "")
  %rest:form-param("file","{$file}")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %public
function graph:uploadGraph($graphURI as xs:string, $file as map(*)){
    if(r:datasetExists())  
    then(
      if($graphURI != "")
      then(
        if(not(graph:isExists($graphURI)))
        then(
          let $datasetEndpoint := graph:datasetEndpoint()
          let $rdf := 
            parse-xml(
              convert:binary-to-string(map:get($file, map:keys($file)[1]))
            )/child::* 
          return
            fuseki2:uploadGraph($rdf, $graphURI, $datasetEndpoint)
        )
        else(
          <rest:response><http:response status="409"/></rest:response>, 
          'Используйте метод PUT'
        )
      )
      else(
          <rest:response><http:response status="400"/></rest:response>,
          'graphURI - не указано имя графа обязательный параметр'
      )
    )
    else(
      <rest:response><http:response status="404"/></rest:response>,
      'Датасет не существет'
    )
};

(: обновляет RDF-ресурс в графе датасета пользователя :)
declare 
  %rest:PUT
  %rest:form-param("graphURI","{$graphURI}", "")
  %rest:form-param("file","{$file}")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %private
function graph:updateGraph($graphURI as xs:string, $file as map(*)){
    if(r:datasetExists())  
    then(
      if(graph:isExists($graphURI))
      then(
        let $datasetEndpoint := graph:datasetEndpoint()
        let $rdf := 
          parse-xml(
            convert:binary-to-string(map:get($file, map:keys($file)[1]))
          )/child::* 
        let $result :=
          (
            fuseki2:deleteGraph($graphURI, $datasetEndpoint),
            fuseki2:uploadGraph($rdf, $graphURI, $datasetEndpoint)
          )
        return
          if($result[1]="200" and $result[2]="200")
          then(
            <rest:response><http:response status="200"/></rest:response>
          )
      )
      else(
        <rest:response><http:response status="404"/></rest:response>,
        'Граф <' || $graphURI  || '> не существует. Исользуйте метод POST.'
      )
    )
    else(
      <rest:response><http:response status="404"/></rest:response>,
      'Датасет пользователя не существует'
    )
};

(:  проверяет наличие графа в хранилище :)
declare function graph:isExists($graphURI as xs:string)
{
  let $graphsList :=
    fuseki2:get(
      'SELECT DISTINCT ?g WHERE { GRAPH ?g {?s ?p ?o;} }',
      graph:datasetEndpoint()
    )//g/value/text()
  return
    $graphsList = $graphURI
};

declare 
  %rest:GET
  %output:method('text')
  %rest:query-param("graphURI", "{$graphURI}", "")
  %rest:path("/trac/api/v0.1/u/rdf/graph/exists")
  %private
function graph:graphExists($graphURI as xs:string)
{
  if($graphURI!='')
  then(
    if(graph:isExists($graphURI))
    then(<rest:response><http:response status="200"/></rest:response>)
    else(<rest:response><http:response status="404"/></rest:response>)
   )
   else(
     <rest:response><http:response status="400"/></rest:response>,
     'Не указано имя графа: graphURI обязательный параметр'
   )
};


(:  удаляет граф из хранилища :)
declare 
  %rest:DELETE
  %output:method('text')
  %rest:query-param("graphURI", "{$graphURI}", "")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %private
function graph:graphDelete($graphURI as xs:string)
{
  if($graphURI!='')
  then(
    let $result := fuseki2:deleteGraph($graphURI, graph:datasetEndpoint())
    return
      if($result="200")
      then(<rest:response><http:response status="200"/></rest:response>)
      else(<rest:response><http:response status="400"/></rest:response>)
  )
   else(
     <rest:response><http:response status="400"/></rest:response>,
     'Не указано имя графа: graphURI обязательный параметр'
   )
};