module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
declare
  %updating
  %rest:POST('{ $data }')
  %rest:path( '/trac/api/v0.1/u/data' )
function data:get( $data )
{
  let $db := db:open( $config:params?имяБазыДанных, "data" )/data
  let $isValid := data:validate( $data )
  return
    if( $isValid/status/text() = "valid"  )
    then(
      insert node $data into $db
    )
    else(
      update:output( <err:ERR06><message>Не верный формат данных</message>{ $isValid }</err:ERR06> )
    )
};

declare function data:validate( $data ){
  let $schema := config:param( "dataStore" ) ||  "xsd/trci.xsd"
  return
    validate:xsd-report( $data, $schema )
};