#lang racket


(require json
         web-server/servlet
         web-server/servlet-env
         web-server/http/json
         web-server/templates
         threading
         nested-hash)


(define coord-api-url "https://iplocation.com/")
(define owm-api-token (getenv "OWM_API_KEY"))
(define owm-api-url "https://api.openweathermap.org/data/2.5/forecast")
(define coord-request-headers
  '("Host: iplocation.com"
    "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0"
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    "Content-type: application/x-www-form-urlencoded; charset=UTF-8"))
(define owm-units "metric")
(define owm-counts 8)
(define owm-icon-url "http://openweathermap.org/img/wn/~a@2x.png")


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
        #:headers coord-request-headers))))


(define (get-hourly-forecast coords)
  (let* ([lat (hash-ref coords 'lat)]
         [lon (hash-ref coords 'lng)]
         [url (format "~a?lat=~a&lon=~a&appid=~a&units=~a&cnt=~a"
               owm-api-url lat lon owm-api-token owm-units owm-counts)])
    (displayln url)
    (port->jsexpr (GET url))))


(define (normalize-forecast-item item)
  (let ([time (second (string-split (hash-ref item 'dt_txt) " "))]
        [humidity (nested-hash-ref item 'main 'humidity)]
        [temp (round (nested-hash-ref item 'main 'temp))]
        [pressure (round (/ (nested-hash-ref item 'main 'pressure) 1.3332))]
        [weather (hash-ref (first (hash-ref item 'weather)) 'description)]
        [wind (nested-hash-ref item 'wind 'speed)]
        [icon-url (hash-ref (first (hash-ref item 'weather)) 'icon)])
    (hasheq
      'time time
      'humidity humidity
      'temp temp
      'pressure pressure
      'weather weather
      'wind wind
      'icon_url icon-url)))


(define (normalize-forecast forecast)
  (let ([city (hash-ref forecast 'city)]
        [new-forecast
          (map normalize-forecast-item (hash-ref forecast 'list))])
    (hasheq 'city city 'list new-forecast)))


(define (forecast req)
  (let* ([coords (get-coords req)]
         [forecast (get-hourly-forecast coords)]
         [new-forecast (normalize-forecast forecast)])
    (displayln new-forecast)
    (response/jsexpr new-forecast)))


(define (main-page req)
  (response/output
    (λ (op) (display (include-template "index.html") op))))


(define (not-found req)
  (response/jsexpr
    (hasheq 'msg "URL not found")
    #:code 404
    #:headers (list (make-header #"Access-Control-Allow-Origin"
                                 #"*"))))


(define-values (api-dispatch api-url)
  (dispatch-rules
    [("") #:method "get" main-page]
    [("forecast") #:method "get" forecast]
    [else not-found]))


(serve/servlet api-dispatch #:servlet-regexp #rx""
                            #:launch-browser? #f
                            #:listen-ip #f)
