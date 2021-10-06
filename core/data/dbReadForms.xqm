module namespace читатьФормы = 'http://iro37.ru/trac/core/data/dbRead.Forms';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../core/utilits/config.xqm';
 

(:~
 : Возвращает фомры пользователя.
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
  читатьФормы:формыПользователя(
    $userID as xs:string, 
    $starts as xs:double, 
    $limit as xs:double,
    $query as xs:string,
    $params as map(*)
  )
{
  let $выбранныеДанные :=
    let $result := 
       xquery:eval(
          $query,
          map{
            '' : читатьФормы:всеФормыПользователя( $userID ),
            'params' : $params
          },
          map{ 'permission' : 'none' }
        )
    return
       if( $limit = 0 )
       then( $result )
       else(
         $result
         [ position() >= $starts and position() <= $starts + $limit - 1 ]
       )
    return
       $выбранныеДанные 
};

declare
  %public
function
  читатьФормы:всеФормыПользователя(
    $userID as xs:string
  ) as element( form )*
{
  db:open('titul24')/forms/form[ @userid = $userID ]
};