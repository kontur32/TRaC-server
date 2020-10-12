module namespace чтениеБД = 'http://iro37.ru/trac/core/data/dbRead';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
  
import module namespace трансформация = 'http://iro37.ru/trac/core/data/transformData'
  at 'transformData.xqm';

(:~
 : Возвращает записи шаблонов пользователя.
 : @param  $userID ID пользователя
 : @param  $starts начальная запись
 : @param  $limit количество записей в выборке
 : @return набор записей шаблонов
 :)
declare
  %public
function
  чтениеБД:шаблоныПользователя(
    $userID as xs:string, 
    $starts as xs:double, 
    $limit as xs:double
  )
{
  let $всеШаблоныПользователя :=
    db:open(
      $config:params?имяБазыДанных,
      $config:settings?названиеРазделаШаблонов
    )/forms/form
     [ @userid = $userID ]
  
  let $выбранныеШаблоны :=
    $всеШаблоныПользователя
      [ position() >= $starts and position() <= $starts + $limit - 1 ]
      /трансформация:formToTRCI( . )
  
  return
    map{
      'шаблоны' : $выбранныеШаблоны,
      'общееКоличество' : count( $всеШаблоныПользователя ),
      'количество' : count( $выбранныеШаблоны ) 
   }
};

(:~
 : Возвращает записи шаблонов .
 : @param  $starts начальная запись
 : @param  $limit количество записей в выборке
 : @return набор записей шаблонов
 :)
declare
  %public
function
  чтениеБД:шаблоны(
    $starts as xs:double, 
    $limit as xs:double
  )
{
  let $всеШаблоныПользователя :=
    db:open(
      $config:params?имяБазыДанных,
      $config:settings?названиеРазделаШаблонов
    )/forms/form
  let $выбранныеШаблоны :=
    $всеШаблоныПользователя
      [ position() >= $starts and position() <= $starts + $limit - 1 ]
      /трансформация:formToTRCI( . )
  return
    map{
      'шаблоны' : $выбранныеШаблоны,
      'общееКоличество' : count( $всеШаблоныПользователя ),
      'количество' : count( $выбранныеШаблоны ) 
   }
};