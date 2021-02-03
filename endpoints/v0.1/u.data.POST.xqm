module namespace data = 'http://iro37.ru/trac/api/v0.1/u/data';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
declare
  %updating
  %rest:POST('{ $data }')
  %rest:path( '/trac/api/v0.1/u/data' )
function data:get( $data as document-node() )
{
  let $db := db:open( $config:params?имяБазыДанных, "data" )/data
  return
    if( $data/child::* instance of element( table ) )
    then(
      insert node $data into $db
    )
    else(
      update:output( <err:ERR06>Не верный формат данных</err:ERR06> )
    )
      
};