module namespace localStore = 'http://iro37.ru/trac/lib/localStore';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../core/utilits/config.xqm';

declare
  %public
function localStore:buildRecord($data, $hash) as element(table){
  <table id="{$hash}" updated="{current-dateTime()}">{$data}</table>
};

declare
  %public
function localStore:readFromStore($hash){
  localStore:readFromStore($config:params?storePath, $hash)
};


declare
  %public
function localStore:readFromStore($storePath as xs:string, $hash){
  let $s := 
    if(file:exists($storePath))
    then(fetch:xml($storePath)/store)
    else(<store/>)
  return
    $s/table[@id=$hash]
};

declare
  %public
function localStore:saveToStore($data){
  localStore:saveToStore($config:params?storePath, $data)
};

declare
  %public
function localStore:saveToStore($storePath as xs:string, $data){
  let $s := 
    if(file:exists($storePath))
    then(fetch:xml($storePath)/store)
    else(<store/>)
  let $updateData := 
    if($s/table[@id=$data/@id])
    then($s update  replace node ./table[@id=$data/@id] with $data)
    else($s update  insert node $data into . )
  return
    file:write($storePath, $updateData)
};