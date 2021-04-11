module namespace index = "http://iro37.ru/trac/api/v0.1/u/data/search/patient/index";

import module namespace читатьБД = 'http://iro37.ru/trac/core/data/dbRead.Data' 
  at '../../../core/data/dbReadData.xqm';

import module namespace config = 'http://iro37.ru/trac/core/utilits/config' 
  at '../../../core/utilits/config.xqm';

(: обновляет индекс пациентов в хранилище :)
declare 
  %rest:path('/trac/api/v0.1/p/data/{ $userID }/index.patient')
function index:main ( $userID ){
  let $data :=
    читатьБД:данныеПользователя( $userID, 1, 0, '.' )?шаблоны
  
  let $записиОПриеме := $data[ @templateID = 'c1d33e2e-0f07-41bc-ab93-a6dc1fd51ee6' ]
  let $всеПациенты := $data[ @templateID = 'ad52a99b-2153-4a3f-8327-b23810fb38e4' ]
   
  let $идентификаторыПациентовПоПоследнейЗаписи := 
    index:идентификаторыПациентовПоПоследнейЗаписи( $записиОПриеме )
  
  let $идентификаторыПациентовБезЗаписей := 
      for $i in $всеПациенты[ row[ not( @id/data() = $идентификаторыПациентовПоПоследнейЗаписи ) ] ]
      where xs:dateTime( $i/@updated/data() ) instance of xs:dateTime
      return 
        [ $i/row/@id/data(), substring-before( $i/@updated/data(), '+' ) ]
  
  let $идентификаторыПациентовОтсортированные :=
      for $i in ( $идентификаторыПациентовБезЗаписей, $идентификаторыПациентовПоПоследнейЗаписи )
      where starts-with( $i?1, 'http://dbx.iro37.ru/promis/сущности/пациенты#' )
      let $dateTime := xs:dateTime( $i?2 )
      order by $dateTime
      return
        $i
  
  let $индекс := 
    <table>
      <row id = "http://dbx.iro37.ru/promis/сущности/индексы/пациентыПоДате">
        {
          for $i in $идентификаторыПациентовОтсортированные
          count $c
          return
            <cell id = "{ $i?1 }" dateTime = '{ $i?2 }'>{ $c }</cell>
        }
      </row>
    </table>
    let $путьХранилища :=
      Q{org.basex.util.Prop}HOMEDIR() || 'webapp/TRaC-server/store/' || $userID
    return
      (
        file:write(  $путьХранилища ||'/index.patient.xml', $индекс ),
        <status>ОК</status>
      )
};



(: возвращает для каждого пациента последнюю по времени запись о приеме :)
declare 
  %private
function 
  index:идентификаторыПациентовПоПоследнейЗаписи( $записи as element( table )* )
{ 
    for $i in $записи/row
    where not( empty( $i/cell[ @id="https://schema.org/Date" ]/text() ) )
    let $p := $i/cell[ @id = ( 'partID' ) ]/text()
    let $order := index:датаВремяЗаписи( $i )
    order by $order
    group by $p
    return
      [
        $i[ last() ]/cell[ @id = ( 'partID' ) ]/text(),
        xs:string( index:датаВремяЗаписи( $i[ last() ] ) )
      ]
};

(: возвращает дату и время записи :)
declare 
  %private
function index:датаВремяЗаписи( $var )
   as xs:dateTime
{
  let $d :=  
    $var/cell[@id="https://schema.org/Date"]/text()
  let $t :=  
      $var/cell[ @id="https://schema.org/Time" ]/text() || ":00.001" 
  return
    try{ xs:dateTime( $d || 'T' || $t ) }catch*{ xs:dateTime( '2000-12-31T23:59:59.999' ) }
};