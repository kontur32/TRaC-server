(:
  функции получения ресурсов по WebDAV
:)

module namespace dav = 'http://dbx.iro37.ru/zapolnititul/api/v2.1/dav/';

declare
  %public
function dav:получитьСвойстваПапки( $access_token, $path ){  
  let $params := 
    map{
      'method' : 'PROPFIND',
      'path' : $path
    }
  return
    dav:запрос( $access_token, $params )
};

declare
  %public
function dav:получитьФайл( $access_token, $path ){  
  let $params := 
    map{
      'method' : 'GET',
      'path' : $path
    }
  return
    dav:запрос( $access_token, $params )[ 2 ]
};

declare
  %private
function dav:запрос( $access_token, $params ){
  let $result := 
    http:send-request(
        <http:request method='{ $params?method }'
           href= '{ iri-to-uri( $params?path ) }' >
          <http:header name="Authorization" value= '{ "Bearer " || $access_token }' />
        </http:request>
    )
  return
    $result
};