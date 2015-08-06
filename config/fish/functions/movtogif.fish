function movtogif -d "Convert Quicktime .mov to .gif"
  ffmpeg -i "$argv[1]" -vf scale=800:-1 -r 10 -f image2pipe -vcodec ppm - |\
  convert -delay 5 -layers Optimize -loop 0 - "$argv[2]"
end
