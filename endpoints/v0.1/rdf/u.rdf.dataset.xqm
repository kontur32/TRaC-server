module namespace rdf = 'http://iro37.ru/trac/api/v0.1/u/rdf/dataset';

import module namespace c = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../../core/utilits/config.xqm';

import module namespace f2 = 'http://garpix.com/semantik/app/fuseki2' 
  at '../../../lib/client.fuseki2.xqm';

(: тип датасета :)
declare function rdf:dbType(){
  'tdb2'
};

(: генерирует URI датасета :)
declare function rdf:datasetName(){
  c:param('authDomain') || ':' || session:get('userID')
};
(: генерирует URL датасета :)
declare function rdf:datasetEndpoint(){
      c:param('rdfEndpoint') || '$/datasets'
};

declare
  %public
  %rest:method('GET')
  %output:method('text')
  %rest:path('/trac/api/v0.1/u/rdf/dataset')
function rdf:datasetExists(){
  let $url := rdf:datasetEndpoint() || '/' || rdf:datasetName()
  let $result := try{json:doc($url)/json}catch*{}
  let $output :=
    if($result instance of element(json))
    then(true())
    else(false())
  return
    xs:string($output)
};

declare
  %public
  %rest:POST
  %rest:path('/trac/api/v0.1/u/rdf/dataset')
function rdf:datasetCreate(){
    if(rdf:datasetExists()='true')
    then('200')
    else(
      let $url :=
        web:create-url(
          rdf:datasetEndpoint(),
          map{
            'dbType':rdf:dbType(),
            'dbName':rdf:datasetName(),
            'state':'active'
          }
        )
      let $response := 
        http:send-request(<http:request method='POST'/>, $url)
      return
         $response[1]/@status/data()
    )
};