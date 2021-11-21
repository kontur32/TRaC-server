module namespace rdf = "http://iro37.ru/trac/api/v0.1/u/data/stores/trciToRDF";

import module namespace functx = 'http://www.functx.com';
import module namespace dateTime = "dateTime" at 'http://iro37.ru/res/repo/dateTime.xqm';

declare function rdf:id($record as element(row), $schemaID as xs:string){
  'http://lipers.ru/сущности/ученики#' ||
  $record/cell[@label="номер личного дела"]/text()
};

declare function rdf:parse($item, $parser){
  if($parser)
  then(dateTime:dateParse($item))
  else($item)
};

declare
  %public
function rdf:trci($data, $schema){
  let $properties := $schema/row/cell/Q{https://titul24.ru/schema/}property
  return
    element{'table'}{
      $data/@label,
      for $row in $data/row
      return
        element{'row'}{
          attribute {'id'}{rdf:id($row, $schema/@id/data())},
          for $cell in $row/cell
          where $properties[label=$cell/@label]/@id/data()
          return
            element{'cell'}{
              attribute{'id'}{$properties[label=$cell/@label]/@id/data()},
              $cell/@label,
              rdf:parse($cell/text(), $properties[label=$cell/@label]/parser/text())
            }
        }
      }
};

declare
  %public
function rdf:rdf($table as element(table)){
  element{'table'}{
     $table/@label,
     for $row in $table/row
     return
       element{'row'}{
        $row/@id,
        for $cell in $row/cell
        let $uri := functx:substring-before-last($cell/@id/data(), '/')
        let $local := functx:substring-after-last($cell/@id/data(), '/')
        return
          element{QName($uri, $local)}{$cell/text()}
      }
   }
};