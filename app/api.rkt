#lang racket


(require json
         net/url
         web-server/dispatch
         web-server/servlet
         web-server/servlet-env
         web-server/http/json
         threading)


(define coord-api "https://iplocation.com/")


(define (port->jsexpr port)
  (~> port
    port->string
    string->jsexpr))


(define (POST url-str #:payload [payload empty] #:headers [headers empty])
  (post-pure-port
    (string->url url-str)
    (unless (empty? payload) payload)
    (unless (empty? headers) headers)))


(define (get-coords req)
  (let* ([client-ip (request-client-ip req)]
         [payload (string->bytes/utf-8 (format "ip=~a" client-ip))])
    (port->jsexpr
      (POST
        coord-api
        #:payload payload
        #:headers '("Host: iplocation.com"
                    "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0"
                    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
                    "Content-type: application/x-www-form-urlencoded; charset=UTF-8")))))


(define (get-forecast coords)
  null)


(define (forecast req)
  (let* ([coords (get-coords req)]
         [forecast (get-forecast coords)])
    (response/jsexpr coords)))


(define (not-found req)
  (response/jsexpr
    (hasheq 'msg "URL not found")
    #:code 404))


(define-values (api-dispatch api-url)
  (dispatch-rules
    [("forecast") #:method "get" forecast]
    [else not-found]))


(serve/servlet api-dispatch #:servlet-regexp #rx""
                            #:launch-browser? #f
                            #:listen-ip #f)
