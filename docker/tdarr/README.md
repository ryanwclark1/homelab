docker run \
    --device=/dev/dri:/dev/dri \
    ghcr.io/haveagitgat/tdarr_node:latest \
    /bin/bash -e \
    -c 'ffmpeg \
            -hwaccel_output_format qsv -qsv_device /dev/dri/renderD128 -f lavfi -i color=c=black:s=256x256:d=1:r=30 \
            -c:v:0 libsvtav1 \
            -f null /dev/null'


docker run \
    --device=/dev/dri:/dev/dri \
    ghcr.io/haveagitgat/tdarr_node:latest \
    /bin/bash -e \
    -c 'ffmpeg \
            -hwaccel_output_format qsv -qsv_device /dev/dri/renderD128 -f lavfi -i color=c=black:s=256x256:d=1:r=30 \
            -c:v:0 av1_qsv \
            -f null /dev/null'


ffmpeg -hwaccel_output_format qsv -qsv_device /dev/dri/renderD128 -f lavfi -i color=c=black:s=256x256:d=1:r=30 -c:v:0 av1_qsv -f null /dev/null

curl -o /tmp/sample.mkv -l https://samples.tdarr.io/api/v1/samples/sample__2160__libx264__aac__30s__video.mkv
curl -o /tmp/sample.mkv -l https://samples.tdarr.io/api/v1/samples/sample__1080__libx264__aac__30s__video.mkv;

ffmpeg -loglevel verbose -hwaccel vaapi -hwaccel_device ${DEVICE:-/dev/dri/renderD128} -hwaccel_output_format qsv -i /tmp/sample.mkv -c:v:0 av1_vaapi -b_strategy 1 -bf 7 -g 256 -fps_mode passthrough -y /tmp/sample-out3.mkv


ffmpeg -loglevel verbose -init_hw_device vaapi=va:${DEVICE:-/dev/dri/renderD128} -init_hw_device vaapi=hw@va -an -f rawvideo -pix_fmt yuv420p -framerate $framerate -i /tmp/sample.mkv -c:v:0 av1_vaapi -b_strategy 1 -bf 7 -g 256 -fps_mode passthrough -y /tmp/sample-out4.mkv

apk add mesa-vulkan-intel linux-firmware-intel xf86-video-intel intel-gmmlib intel-gmmlib-dev intel-media-driver-dev intel-media-driver libva-intel-driver intel-media-sdk intel-media-sdk-dev intel-media-sdk-tracer libva libva-dev libva-utils libva-vdpau-driver

DEV.L. av1                  Alliance for Open Media AV1 (decoders: libdav1d libaom-av1 av1 av1_qsv) (encoders: libaom-av1 librav1e libsvtav1 av1_qsv av1_vaapi)

export inputyuv=/storage/other/.other/Petite18/Petite18\ -\ 2014-03-23\ -\ Fuck\ Me\ Step\ Daddy\ \[WEBDL-720p\].mp4
export imput=/tmp/sample-in.mp4
export output=/tmp/sample-out5.mp4
ffmpeg -init_hw_device vaapi=va:${DEVICE:-/dev/dri/renderD128} -init_hw_device qsv=hw@va -an \
  -f rawvideo -pix_fmt yuv420p -s:v ${width}x${height} -framerate $framerate -i $inputyuv \
  -frames:v $numframes -c:v av1_qsv -preset $preset -profile:v main -async_depth 1 \
  -b:v $bitrate -maxrate $bitrate -minrate $bitrate -bufsize $((2 * bitrate)) \
  -rc_init_occupancy $bitrate -low_power ${LOW_POWER:-true} -look_ahead_depth $lad -extbrc 1 \
  -b_strategy 1 -adaptive_i 1 -adaptive_b 1 -bf 7 -g 256 -strict -1 \
  -fps_mode passthrough -y $output

apk update
apk add build-base cmake git
cmake -B _build -DCMAKE_INSTALL_PREFIX=$VPL_INSTALL_DIR
cmake --build _build
cmake --install _build

ffmpeg -loglevel verbose -y -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi -i /storage/other/.other/Petite18/Petite18\ -\ 2014-03-23\ -\ Fuck\ Me\ Step\ Daddy\ \[WEBDL-720p\].mp4 -c:v h264_vaapi /tmp.mp


cp /storage/other/.other/Petite18/Petite18\ -\ 2014-03-23\ -\ Fuck\ Me\ Step\ Daddy\ \[WEBDL-720p\].mp4 /tmp/input.mp4

cp /storage/other/.other/Bratty\ Sis/Bratty\ Sis\ -\ 2019-09-20\ -\ Is\ That\ a\ Boner\ -\ S11-E4\ \[WEBDL-1080p\].mp4 /tmp/input.mp4

ffmpeg -hwaccel qsv -hwaccel_output_format qsv -c:v h264_qsv -i /tmp/sample-in.mp4 -c:v av1_qsv /tmp/sample-out.mp4


build-base gcc cmake

ffmpeg \
-loglevel verbose \
-hwaccel qsv \
-qsv_device ${DEVICE:-/dev/dri/renderD128} \
-c:v $inputcodec -an -i $input


ffmpeg -loglevel verbose -hwaccel qsv -qsv_device ${DEVICE:-/dev/dri/renderD128} -c:v $inputcodec -an -i ${input:-/tmp/sample.mp4} \
  -frames:v $numframes -c:v av1_qsv -preset $preset -profile:v main -async_depth 1 \
  -b:v $bitrate -maxrate $bitrate -minrate $bitrate -bufsize $((2 * bitrate)) \
  -rc_init_occupancy $bitrate -b_strategy 1 -bf 7 -g 256 \
  -fps_mode passthrough -y ${output:-/tmp/sample-out.mp4}


ffmpeg -loglevel verbose -hwaccel auto -init_hw_device vaapi=va:${DEVICE:-/dev/dri/renderD128} -hwaccel_output_format vaapi -i ${input:-/tmp/sample.mkv} -c:v:0 av1_vaapi -bf 7 -g 256 -fps_mode passthrough -y ${output:-/tmp/sample-out.mkv}


ffmpeg -hwaccel qsv -qsv_device ${DEVICE:-/dev/dri/renderD128} -c:v $inputcodec -extra_hw_frames $lad -an -i $input \
  -frames:v $numframes -c:v av1_qsv -preset $preset -profile:v main -async_depth 1 \
  -b:v $bitrate -maxrate $((2 * bitrate)) -bufsize $((4 * bitrate)) \
  -rc_init_occupancy $((2 * bitrate)) -low_power ${LOW_POWER:-true} -look_ahead_depth $lad -extbrc 1 \
  -b_strategy 1 -adaptive_i 1 -adaptive_b 1 -bf 7 -g 256 -strict -1 \
  -fps_mode passthrough -y $output


ffmpeg -init_hw_device qsv=hw -filter_hw_device hw -i /tmp/input.mp4 -c:v av1_qsv /tmp/output.mp4

ffmpeg -loglevel debug -stats -hwaccel qsv -qsv_device ${DEVICE:-/dev/dri/renderD128} -init_hw_device qsv=hw -filter_hw_device hw -c:v h264_qsv -i /tmp/input.mp4 -c:v av1_qsv -b:v 3000k /tmp/output2.mp4

ffprobe -v verbose -show_format -show_streams /tmp/output.mp4

ffmpeg -loglevel debug -stats -hwaccel qsv -i /tmp/input.mp4 -c:v av1_qsv -preset veryslow -o /tmp/output2.mp4
ffmpeg -loglevel debug -stats -init_hw_device qsv=hw -filter_hw_device hw -i /tmp/input.mp4 -c:v av1_qsv -preset veryslow /tmp/output2.mp4
