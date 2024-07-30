

https://github.com/intel/media-delivery/blob/master/doc/quality.rst

###HEVC
# triggers EncTools with look ahead (quality boost):
ffmpeg <...> -g 256 -b_strategy 1 -bf 7 -extbrc 1 -look_ahead_depth 40 <...>

VBR
-b:v $bitrate -maxrate $((2 * bitrate))
-bufsize $((4 * bitrate))
-rc_init_occupancy $((2 * bitrate))

CBR
-b:v $bitrate -minrate $bitrate -maxrate $bitrate
-bufsize $((2 * bitrate))
-rc_init_occupancy $bitrate

###AV1

##EncTools
ffmpeg <...> -g 256 -b_strategy 1 -bf 7 -extbrc 1 -look_ahead_depth $lad -adaptive_i 1 -adaptive_b 1 -strict -1 -extra_hw_frames $lad

VBR
-b:v $bitrate -maxrate $((2 * bitrate))
-bufsize $((4 * bitrate))
-rc_init_occupancy $((2 * bitrate))

CBR
-b:v $bitrate -minrate $bitrate -maxrate $bitrate
-bufsize $((2 * bitrate))
-rc_init_occupancy $bitrate
