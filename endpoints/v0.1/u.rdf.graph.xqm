module namespace rdf = 'http://iro37.ru/trac/api/v0.1/u/rdf/dataset/post';

import module namespace c = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';

import module namespace f2 = 'http://garpix.com/semantik/app/fuseki2' 
  at '../../lib/client.fuseki2.xqm';

import module namespace r = 'http://iro37.ru/trac/api/v0.1/u/rdf/dataset'
  at 'u.rdf.dataset.xqm';

(: генерирует URL датасета :)
declare function rdf:datasetEndpoint(){
  c:param('rdfEndpoint') || c:param('authDomain') || ':' || session:get('userID')
};

(:  публикует RDF-ресурс в графе датесета пользователя :)
declare 
  %rest:POST
  %rest:form-param("graphURI","{$graphURI}", "")
  %rest:form-param("file","{$file}")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %private
function rdf:uploadGraph($graphURI as xs:string, $file as map(*)){
    if(r:datasetExists())  
    then(
      if(not(rdf:graphExists($graphURI)='true'))
      then(
        if($graphURI != "")
        then(
          let $datasetEndpoint := rdf:datasetEndpoint()
          let $rdf := 
            parse-xml(
              convert:binary-to-string(map:get($file, map:keys($file)[1]))
            )/child::* 
          return
            f2:uploadGraph($rdf, $graphURI, $datasetEndpoint)
        )
        else('Необходимо указать имя графа')
      )
      else('Граф <' || $graphURI  || '> существует. Исользуйте метод PUT.')
    )
    else('Датасет пользователя не существует')
};

(: обновляет RDF-ресурс в графе датасета пользователя :)
declare 
  %rest:PUT
  %rest:form-param("graphURI","{$graphURI}", "")
  %rest:form-param("file","{$file}")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %private
function rdf:updateGraph($graphURI as xs:string, $file as map(*)){
    if(r:datasetExists())  
    then(
      if(rdf:graphExists($graphURI)='true')
      then(
        if($graphURI != "")
        then(
          let $datasetEndpoint := rdf:datasetEndpoint()
          let $rdf := 
            parse-xml(
              convert:binary-to-string(map:get($file, map:keys($file)[1]))
            )/child::* 
          return
            (
              f2:deleteGraph($graphURI, $datasetEndpoint),
              f2:uploadGraph($rdf, $graphURI, $datasetEndpoint)
            )
        )
        else('Необходимо указать имя графа')
      )
      else('Граф <' || $graphURI  || '> не существует. Исользуйте метод POST.')
    )
    else('Датасет пользователя не существует')
};

(:  проверяет наличие графа в хранилище :)
declare 
  %rest:GET
  %output:method('text')
  %rest:query-param("graphURI", "{$graphURI}", "")
  %rest:path("/trac/api/v0.1/u/rdf/graph/exists")
  %private
function rdf:graphExists($graphURI as xs:string)
{
  if($graphURI!='')
  then(
    let $graphsList :=
      f2:get(
        'SELECT DISTINCT ?g WHERE { GRAPH ?g {?s ?p ?o;} }',
        rdf:datasetEndpoint()
      )//g/value/text()
    return
      xs:string($graphsList = $graphURI)
   )
   else('Необходимо указать граф в параметре graphURI')
};


(:  удаляет граф из хранилища :)
declare 
  %rest:DELETE
  %output:method('text')
  %rest:query-param("graphURI", "{$graphURI}", "")
  %rest:path("/trac/api/v0.1/u/rdf/graph")
  %private
function rdf:graphDelete($graphURI as xs:string)
{
  if($graphURI!='')
  then(
    f2:deleteGraph($graphURI, rdf:datasetEndpoint())
  )
   else('Необходимо указать граф в параметре graphURI')
};