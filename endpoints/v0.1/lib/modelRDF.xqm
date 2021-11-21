module namespace sch = "http://iro37.ru/trac/api/v0.1/u/data/stores/modelRDF";

declare 
  %public
function sch:model(
  $fields as element(csv)
) as element(table) {
  let $about :=  $fields/record[ID/text() = "__ОПИСАНИЕ__"]
  return
    element {"table"} {
      attribute {'id'}{$about/schemaID/text()},
      attribute {'context'}{$about/contexURI/text()},
      attribute {'resource'}{$about/resourceURI/text()},
      element {'row'}{
        element{'cell'}{
          attribute{'id'}{'properties'},
          for $record in $fields/record
          where not( $record/ID/text() = "__ОПИСАНИЕ__" )
          return
            element {QName("https://titul24.ru/schema/","t24:property")} {
              attribute {"id"} {$record/идентификаторПризнака/text()},
              element {"label"} {$record/ID/text()},
              if($record/парсер/text())
              then(
                element {"parser"} {$record/парсер/text()}
              )
           }
       }
     }
   }
};