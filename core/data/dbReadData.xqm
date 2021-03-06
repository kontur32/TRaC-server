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
 : @param  $query запрос, применяемый к данным пользователя
 : @param  $params параметры передаваемые в запрос $query
 : @return набор записей данных
 :)
declare
  %public
function
  читатьБД:данныеПользователя(
    $userID as xs:string, 
    $starts as xs:double, 
    $limit as xs:double,
    $query as xs:string,
    $params as map(*)
  )
{
  let $всеДанныеПользователя :=
    let $данные :=
       db:open( $config:params?имяБазыДанных, 'data' )/data/table
       [ @userID = $userID ]
       [ if( @status )then( @status = 'active' )else( true() ) ]
       
    for $i in $данные
    let $id := $i/row/@id/data()
    group by $id
    return
     $i[ last() ]
  
  let $выбранныеДанные :=
    xquery:eval(
      $query,
      map{
        '' : $всеДанныеПользователя,
        $params?имяПеременойПараметров : $params?значенияПараметров
      },
      map{ 'permission' : 'admin' }
    )
      [ position() >= $starts and position() <= $starts + $limit - 1 ]
      
  return
    map{
      'шаблоны' : $выбранныеДанные,
      'общееКоличество' : count( $всеДанныеПользователя ),
      'количество' : count( $выбранныеДанные ) 
   }
};


(:~
 : Возвращает все записи данных пользователя.
 : @param  $userID ID пользователя
 : @return набор записей данных
 :)
declare
  %public
function
  читатьБД:всеДанныеПользователя(
    $userID as xs:string
  )
{
   db:open( $config:params?имяБазыДанных, 'data' )/data/table
   [ @userID = $userID ]
};