#lang racket


(require json
         net/url
         web-server/dispatch
         web-server/servlet
         web-server/servlet-env
         web-server/http/json
         threading)


(define coord-api-url "https://iplocation.com/")
(define owm-api-token (getenv "OWM_API_KEY"))
(define owm-api-url "https://api.openweathermap.org/data/2.5/forecast")


(define (port->jsexpr port)
  (~> port
    port->string
    string->jsexpr))


(define (POST url-str #:payload [payload empty] #:headers [headers empty])
  (post-pure-port
    (string->url url-str)
    (unless (empty? payload) payload)
    (unless (empty? headers) headers)))


(define (GET url-str)
  (get-pure-port
    (string->url url-str)))


(define (get-coords req)
  (let* ([client-ip (request-client-ip req)]
         [payload (string->bytes/utf-8 (format "ip=~a" client-ip))])
    (port->jsexpr
      (POST
        coord-api-url
        #:payload payload
        #:headers '("Host: iplocation.com"
                    "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0"
                    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
                    "Content-type: application/x-www-form-urlencoded; charset=UTF-8")))))


(define (get-hourly-forecast coords)
  (let* ([lat (hash-ref coords 'lat)]
         [lon (hash-ref coords 'lng)]
         [url (format "~a?lat=~a&lon=~a&appid=~a"
               owm-api-url lat lon owm-api-token)])
    (displayln url)
    (port->jsexpr (GET url))))


(define (forecast req)
  (let* ([coords (get-coords req)]
         [forecast (get-hourly-forecast coords)])
    (response/jsexpr forecast)))


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
