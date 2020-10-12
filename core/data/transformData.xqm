module namespace трансформация = 'http://iro37.ru/trac/core/data/transformData';

(:~
 : Преобразуте записи шаблона в формат TRCI.
 : @param  $templateRecord запись шаблона
 : @return запись шаблона в формате TRCI
 :)
declare
  %public
function
  трансформация:formToTRCI( $templateRecord as element() ) as element( table )
{
  element{ 'table' }{
         $templateRecord/attribute::*,
         for $i in $templateRecord/csv/record
         return
           element{ 'row' }{
             attribute{ 'id' }{ $i/ID/text()},
             for-each( $i/child::*, function( $v ){
               element{ 'cell' }{
                 attribute{ 'id' }{ $v/name() },
                 $v/text()
               }
             })
           }
       }
};