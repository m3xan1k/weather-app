#lang racket


(require web-server/dispatch
         web-server/servlet
         web-server/servlet-env
         json)


(define coord-api 'https://iplocation.com/)


(define (port->jsexpr port)
  (-> port
    (port->string)
    (string->jsexpr)))


(define (POST url payload)
  null)


(define (get-coords req)
  (let* ([client-ip (request-client-ip req)]
         [payload (hasheq 'ip client-ip)])
    null))


(define (get-forecast coords)
  null)


(define (forecast req)
  (let ([forecast (get-forecast (get-coords req))])
    null))


(define-values (api-dispatch api-url)
  (dispatch-rules
    [("forecast") forecast]))
