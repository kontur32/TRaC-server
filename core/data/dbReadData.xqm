module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace трансформация = 'http://iro37.ru/trac/core/data/transformData'
  at 'transformData.xqm';

(:~
 : Возвращает записи данных пользователя.
 : @param  $userID ID пользователя
 : @param  $starts начальная запись
 : @param  $limit количество записей в выборке
 : @return набор записей данных
 :)
declare
  %public
function
  читатьБД:данныеПользователя(
    $userID as xs:string, 
    $starts as xs:double, 
    $limit as xs:double
  )
{
   let $всеДанныеПользователя :=
    db:open(
      $config:params?имяБазыДанных,
      'data'
    )/data/table
    [ @userID = $userID ]
  let $выбранныеДанные :=
    $всеДанныеПользователя
      [ position() >= $starts and position() <= $starts + $limit - 1 ]
      
  return
    map{
      'шаблоны' : $выбранныеДанные,
      'общееКоличество' : count( $всеДанныеПользователя ),
      'количество' : count( $выбранныеДанные ) 
   }
};