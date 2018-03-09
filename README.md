
![system](https://github.com/atyenoria/janus-webrtc-gateway-docker/blob/master/system.png "system")
[![Build Status](https://travis-ci.org/atyenoria/janus-webrtc-gateway-docker.svg?branch=master)](https://travis-ci.org/atyenoria/janus-webrtc-gateway-docker)
 # Introduction
This is a docker dev image for Janus Webrtc Gateway, it is based on https://github.com/atyenoria/janus-webrtc-gateway-docker and is not meant for production. Janus Gateway is still under active development phase. So, as the official docs says, some minor modification of the middleware library versions happens frequently. I try to deal with such a chage as much as I can. If you need any request about this repo, free to contact me. About the details of setup for this docker image, you should read the official docs https://janus.conf.meetecho.com/index.html carefully. 

# Characteristics
- libwebsocket 2.2.0, build with LWS_MAX_SMP=1 for single thread processing
- libsrtp 2.0.0
- coturn 4.5.0.6
- openresty 1.11.2.3
- golang 1.7.5 for building boringssl
- compile with the latest ref count branch for memory racing condition crash
- compile with only videoroom, audiobridge, streaming plugin
- enable janus-pp-rec
- GDB, Address Sanitizer(optional, see Dockerfile) for getting more info when crashing
- not compile datachannel
- boringssl for performance and handshake error
- nginx-rtmp-module and ffmpeg compile for MCU functionalilty experiment. For example, WEBRTC-HLS, DASH, RTMP...etc
- use --net=host for network performance. If you use docker network, some overhead might appear (ref. https://hub.docker.com/_/consul/)

# janus ./configure

```
libsrtp version:           2.0.x
SSL/crypto library:        BoringSSL
DTLS set-timeout:          yes
DataChannels support:      yes
Recordings post-processor: yes
TURN REST API client:      no
Doxygen documentation:     no
Transports:
    REST (HTTP/HTTPS):     yes
    WebSockets:            yes (new API)
    RabbitMQ:              no
    MQTT:                  no
    Unix Sockets:          yes
Plugins:
    Echo Test:             yes
    Streaming:             yes
    Video Call:            yes
    SIP Gateway:           yes
    Audio Bridge:          yes
    Video Room:            yes
    Voice Mail:            yes
    Record&Play:           yes
    Text Room:             yes
Event handlers:
    Sample event handler:  no
```

# Setup
```
docker build --no-cache -t giorgioma/janus-gateway-docker .
docker run --rm  --name="janus" -idt -p 80:80 -p 443:443 -p 8088:8088 -p 8004:8004/udp -p 8004:8004 -p 8089:8089 -p 8188:8188 -t giorgioma/janus-gateway-docker
docker exec -it /bin/bash janus
```
You should read the official doc https://janus.conf.meetecho.com/index.html carefully.
# RTMP -> RTP -> WEBRTC
```
IP=0.0.0.0
PORT=8888
/root/bin/ffmpeg -y -i  "rtmp://$IP:80/rtmp_relay/$1  live=1"  -c:v libx264 -profile:v main -s 640x480  -an -preset ultrafast  -tune zerolatency -f rtp  rtp://$IP:$PORT
```
you should use janus streaming plugin <br>
https://github.com/meetecho/janus-gateway/blob/8b388aebb0de3ccfad3b25f940f61e48e308e604/plugins/janus_streaming.c

# WEBRTC -> RTP -> RTMP
```
IP=0.0.0.0
PORT=8888
SDP_FILE=sdp.file
/root/bin/ffmpeg -analyzeduration 300M -probesize 300M -protocol_whitelist file,udp,rtp  -i $SDP_FILE  -c:v copy -c:a aac -ar 16k -ac 1 -preset ultrafast -tune zerolatency  -f flv rtmp://$IP:$PORT/rtmp_relay/atyenoria
```
In order to get the keyframe much easier, it is useful to set  fir_freq=1 in janus conf<br>
you should use janus video room or audiobridge plugin <br>
https://github.com/meetecho/janus-gateway/blob/8b388aebb0de3ccfad3b25f940f61e48e308e604/plugins/janus_videoroom.c <br>
https://github.com/meetecho/janus-gateway/blob/8b388aebb0de3ccfad3b25f940f61e48e308e604/plugins/janus_audiobridge.c <br>
After publishing your feed in your room, you should use rtp-forward. The sample javascript command is
```
# Input this in Google Chrome debug console. you must change publisher_id, room, video_port, host, secret for your conf.
var register = { "request" : "rtp_forward", "publisher_id": 3881836128186438, "room" : 1234, "video_port": 8050, "host" : "your ip address", "secret" : "unko" }
sfutest.send({"message": register});
```

