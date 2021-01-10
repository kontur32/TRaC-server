module namespace nc = 'http://iro37.ru/trac/lib/nextCloud';

import module namespace nextCloud = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/nextCloud/'
  at '../../zapolniTitul/api/v2.1/functions/nextCloud.xqm';

declare function nc:getResource( $storeRecord, $tokenRecordsFilePath, $path  ){
  nextCloud:получитьФайл( $storeRecord, $tokenRecordsFilePath, $path  )
};