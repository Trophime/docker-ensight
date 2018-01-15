## Running Ensight:

To build base image:
```
docker build -t ensight:10.2.2a -f ./Dockerfile .
```

To run Ensight:
```
xhost local:root
docker run -ti --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
   -v $HOME/.Xauthority:/home/feelpp/.Xauthority --net=host --pid=host --ipc=host \
   --env QT_X11_NO_MITSHM=1 \
   -v /opt/CEI/license8:/opt/licenses \
   ensight:10.2.2a
```
