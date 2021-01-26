module namespace config = 'http://iro37.ru/trac/core/utilits/config';


declare variable $config:params := 
  map:merge(
    for $i in doc( '../../config.xml' )//cell
    return
      map{
        $i/@id/data() : $i/text()
      }
  );
  
declare variable $config:settings := 
  map:merge(
    for $i in doc( '../../settings.xml' )//cell
    return
      map{
        $i/@id/data() : $i/text()
      }
  );
  
(:~
 : Возвращает значение параметра конфигурации.
 : @param  $parametrName имя параметра
 : @return значение параметра
 :)
declare
  %public
function config:param( $parametrName as xs:string ) as xs:string* {
  doc( '../../config.xml' )//cell[ @id = $parametrName ]/text()
};

(:~
 : Возвращает значение параметра настроек.
 : @param  $parametrName имя настройки
 : @return значение настройки
 :)
declare
  %public
function config:setting( $parametrName as xs:string ) as xs:string* {
  doc( '../../settings.xml' )//cell[ @id = $parametrName ]/text()
};

declare function config:log( $fileName, $data, $params ) {
  switch ( $params?mode )
  case 'rewrite'
    return
      file:write-text(
           config:param( 'logDir' ) || $fileName,
            string-join( ( current-dateTime() || '--' || $data, '&#xD;&#xA;' ) )
         )
    case 'add'
    return
      file:append-text(
           config:param( 'logDir' ) || $fileName,
            string-join( ( current-dateTime() || '--' || $data, '&#xD;&#xA;' ) )
         )
   default 
     return
     file:append-text(
         config:param( 'logDir' ) || $fileName,
          string-join( ( current-dateTime() || '--' || $data, '&#xD;&#xA;' ) )
       )
       
};

declare function config:log ( $fileName, $data ) {
  config:log( $fileName, $data, map{ 'mode' : 'add' } )
};