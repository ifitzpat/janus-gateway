(define-module (janus)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix licenses)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages web))

(define-public janus-gateway
  (package
    (name "janus-gateway")
    (version "1.4.0")
    (source (local-file "." "janus-gateway-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-paths
           (lambda* (#:key inputs outputs #:allow-other-keys)
             ;; Make sure the build can find all necessary tools
             #t))
         (replace 'bootstrap
           (lambda _
             ;; Run autogen.sh to generate configure script
             (invoke "sh" "autogen.sh")))
         (add-before 'configure 'set-paths
           (lambda* (#:key inputs outputs #:allow-other-keys)
             ;; Set up pkg-config paths
             (setenv "PKG_CONFIG_PATH"
                     (string-append (getenv "PKG_CONFIG_PATH") ":"
                                    (assoc-ref inputs "libnice") "/lib/pkgconfig"))
             #t)))))
    (native-inputs
     (list autoconf
           automake
           libtool
           pkg-config))
    (inputs
     (list glib
           jansson
           libconfig
           libnice
           libsrtp
           libmicrohttpd
           openssl
           opus
           libogg
           curl
           zlib
           ;; Optional dependencies for additional features
           usrsctp                      ; For DataChannels support
           libwebsockets                ; For WebSocket support
           sofia-sip))                  ; For SIP plugin
    (synopsis "General purpose WebRTC server")
    (description
     "Janus is an open source, general purpose, WebRTC server designed and
developed by Meetecho.  This version of the server is tailored for Linux
systems.  It provides a modular architecture with support for multiple
transport protocols (HTTP REST, WebSockets, RabbitMQ, MQTT, Nanomsg) and
includes various plugins for different use cases such as video conferencing,
streaming, SIP gateway, and more.")
    (home-page "https://janus.conf.meetecho.com/")
    (license gpl3)))

;; Export the package
janus-gateway
