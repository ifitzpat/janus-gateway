(define-module (janus)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnunet)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages telephony)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xiph))

(define-public janus-gateway
  (package
    (name "janus-gateway")
    (version "1.4.0")
    (source (local-file "." "janus-gateway-checkout"
                        #:recursive? #t))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f  ; Skip tests for now
      #:configure-flags
      #~(list (string-append "--prefix=" #$output)
              "--disable-docs"
              "--disable-data-channels"      ; No usrsctp
              "--disable-rabbitmq"           ; No rabbitmq-c
              "--disable-mqtt"               ; No paho-mqtt
              "--disable-nanomsg"            ; No nanomsg
              "--disable-all-loggers")
      #:phases
      #~(modify-phases %standard-phases
          (replace 'bootstrap
            (lambda _
              ;; Run autogen.sh to generate configure script
              (invoke "sh" "autogen.sh"))))))
    (native-inputs
     (list autoconf
           automake
           bash
           libtool
           m4
           pkg-config
           which))
    (inputs
     (list curl
           glib
           jansson
           libconfig
           libmicrohttpd
           libnice
           libogg
           libsrtp
           libwebsockets                ; For WebSocket transport
           openssl
           opus
           sofia-sip                    ; For SIP plugin
           zlib))
    (synopsis "General purpose WebRTC server")
    (description
     "Janus is an open source, general purpose, WebRTC server designed and
developed by Meetecho.  This version of the server is tailored for Linux
systems.  It provides a modular architecture with support for multiple
transport protocols (HTTP REST, WebSockets, RabbitMQ, MQTT, Nanomsg) and
includes various plugins for different use cases such as video conferencing,
streaming, SIP gateway, and more.")
    (home-page "https://janus.conf.meetecho.com/")
    (license license:gpl3+)))

;; Export the package
janus-gateway
