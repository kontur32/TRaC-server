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
  %rest:query-param("graphURI","{$graphURI}", "")
  %rest:form-param("file","{$file}")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %public
function graph:uploadGraph($graphURI as xs:string, $file){
    if(r:datasetExists())  
    then(
      if($graphURI != "")
      then(
        if(not(graph:isExists($graphURI)))
        then(
          let $datasetEndpoint := graph:datasetEndpoint()
          let $rdf := graph:rdf($file)
          let $result := fuseki2:uploadGraph($rdf, $graphURI, $datasetEndpoint)
          return
            if($result="201")
            then(<rest:response><http:response status="201"/></rest:response>)
            else(<rest:response><http:response status="400"/></rest:response>)
        )
        else(
          <rest:response><http:response status="409"/></rest:response>,
          'Граф <' || $graphURI || '> существет. Используйте метод PUT'
          
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
  %rest:query-param("graphURI","{$graphURI}", "")
  %rest:form-param("file","{$file}")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %public
function graph:updateGraph($graphURI as xs:string, $file){
    if(r:datasetExists())  
    then(
      if(graph:isExists($graphURI))
      then(
        let $datasetEndpoint := graph:datasetEndpoint()
        let $rdf := graph:rdf($file)
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

(: конвертирует полученный файл в RDF :)
declare 
  %private
function graph:rdf(
  $file
) as element(Q{http://www.w3.org/1999/02/22-rdf-syntax-ns#}RDF)*
{
  let $fileRaw :=
    if($file instance of map(*))
    then(convert:binary-to-string(map:get($file, map:keys($file)[1])))
    else($file)
  return 
    parse-xml($fileRaw)/child::* 
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
  %rest:path("/trac/api/v0.1/u/rdf/graph")
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
  %public
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