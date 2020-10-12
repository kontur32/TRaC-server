module namespace чтениеБД = 'http://iro37.ru/trac/core/data/dbRead';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace трансформация = 'http://iro37.ru/trac/core/data/transformData'
  at 'transformData.xqm';

(:~
 : Возвращает записи шаблонов пользователя.
 : @param  $userID ID пользователя
 : @return набор записей шаблонов
 :)
declare
  %public
function
  чтениеБД:шаблоныПользователя(
    $userID as xs:string, $starts, $limit
  ) as element()* {
    db:open(
      $config:params?имяБазыДанных,
      $config:settings?названиеРазделаШаблонов
    )/forms/form
    [ @userid = $userID ]
    [ position() >= $starts and position() <= $starts + $limit - 1 ]
    /трансформация:formToTRCI( . )
};