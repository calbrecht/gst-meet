#!/usr/bin/env bash

PIPELINE="${1}"
DOMAIN="${2}"
ROOM="${3}"
shift 3

WSS="wss://${DOMAIN}/xmpp-websocket"

CMD="./target/debug/gst-meet"
CMD_ARGS=( --room-name="$ROOM" --web-socket-url="$WSS" )

youtube() {
    YOUTUBE_URL="https://www.youtube.com/watch?v=vjV_2Ri2rfE"
    youtube_dl_a="nix run f4s#youtube-dl -- -g $YOUTUBE_URL -f 'bestaudio[acodec=opus]'"
    youtube_dl_v="nix run f4s#youtube-dl -- -g $YOUTUBE_URL -f 'bestvideo[vcodec=vp9]'"
    SEND_PIPELINE="curlhttpsrc location=\"$($youtube_dl_a)\" ! queue ! matroskademux name=audiodemux
curlhttpsrc location=\"$($youtube_dl_v)\" ! queue ! matroskademux name=videodemux
audiodemux.audio_0 ! queue ! clocksync name=audio
videodemux.video_0 ! queue ! clocksync name=video"
    CMD_ARGS+=( --send-pipeline="$SEND_PIPELINE" )
}

meeting() {
    SEND_PIPELINE="v4l2src ! queue ! videoscale ! video/x-raw,width=640,height=360 ! videoconvert ! vp9enc buffer-size=1000 deadline=1 name=video
autoaudiosrc ! queue ! audioconvert ! audioresample ! opusenc name=audio"
    CMD_ARGS+=( --send-pipeline="$SEND_PIPELINE" )
}

# from cam to wl
# v4l2src ! videoconvert ! video/x-raw,format=RGBA ! waylandsink

case "${PIPELINE}" in
    meeting) meeting ;;
    *) echo Usage "$0" meeting ; exit 1 ;;
esac

export GST_V4L2_USE_LIBV4L2=1
$CMD "${CMD_ARGS[@]}" "$@"
