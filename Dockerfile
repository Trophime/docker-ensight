ARG PLATFORM=ubuntu
ARG OS=xenial

FROM ${PLATFORM}:${OS}
MAINTAINER Feel++ Support <support@feelpp.org>

ARG DEBUG=1
ARG GRAPHICS=nvidia
ARG HIFIMAGNET=true
ARG TERM=linux
ARG DEBIAN_FRONTEND=noninteractive

# Setup demo environment variables
ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=C.UTF-8

# at the beginning
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#Ubuntu:module-init-tools, Debian: kmod
# install EnSight full
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
      sudo gosu \
      iputils-ping net-tools ca-certificates \
      bash-completion \
      wget curl \
      emacs vim nano \
      tcsh libcurl3 libglu1-mesa libxmu6 libssh2-1 lshw && \
    apt-get clean -y

# NB Mounted licenses key
RUN cd /tmp && \
    wget http://archives.ensight.com/EnSight102/10.2.3a/Full/EnSight102Full-10.2.3a_amd64.deb && \
    dpkg -i EnSight102Full-10.2.3a_amd64.deb && \
    mkdir -p /opt/licenses && \
    ln -sf /opt/licenses/slim8.key /opt/CEI/license8 && \
    rm /tmp/EnSight102Full-10.2.3a_amd64.deb

# # Add Hifimagnet addons (need to be packaged before)
# COPY Ensight_Hifimagnet.tgz /tmp
# RUN cd tmp && \
#     tar zxvf Ensight_Hifimagnet.tgz &&
#     cd EnSight && \
#     sh ./install_magnettools.sh && \
#     rm -f Ensight_Hifimagnet.tgz

# add Graphics driver for better perf
RUN lshw -c video | grep configuration | grep configuration | awk  '{print $2}' | perl -pe 's|driver=||' && \
    if [ x$GRAPHICS != xnone ]; then \
      if [ x$PLATFORM = xubuntu ]; then \
         apt-get install -y  module-init-tools; \
      fi ; \             
      if [ x$PLATFORM = xdebian ]; then \
         apt-get install -y  kmod; \
      fi ; \             
    fi && \ 
    if [ x$GRAPHICS = xnvidia ]; then \
       wget http://us.download.nvidia.com/XFree86/Linux-x86_64/384.98/NVIDIA-Linux-x86_64-384.98.run -O /tmp/NVIDIA-DRIVER.run; \
       sh /tmp/NVIDIA-DRIVER.run -a -N --ui=none --no-kernel-module; \
       rm /tmp/NVIDIA-DRIVER.run; \
    fi && \
    if [ x$GRAPHICS = xintelhd ]; then \
       echo "should install intelhd driver"; \
    fi && \
    if [ x$GRAPHICS = xati ]; then \
       echo "should install ati driver"; \
    fi && \
    if [ x$GRAPHICS = xradeon ]; then \
       echo "should install xradeon driver"; \
    fi

# # add HiFiMagnet plugin
# COPY hifimagnet.tar $HOME
# RUN cd $HOME && \
#     tar xvf hifimagnet.tar && \
#     cd hifimagnet && \
#     sh ./install_magnettools.sh && \
#     rm -rf $HOME/hifimagnet

# Final clean-up
RUN if [ x$DEBUG = x0 ]; then \
       sudo apt-get -y autoremove \
       && sudo apt-get clean \
       && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    ; fi 

# Our helper scripts
COPY start.sh /usr/local/bin/start.sh
#RUN perl -pi -e "s|||g" /usr/local/bin/start.sh

# Define feelpp
RUN useradd -m -s /bin/bash -G sudo,video -u 999 feelpp && \
    echo "feelpp ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Define user
USER feelpp
ENV HOME /home/feelpp 
WORKDIR $HOME

COPY WELCOME /etc/motd

# set alias
RUN echo "alias cp='cp -i'" > $HOME/.bash_aliases && \
    echo "alias egrep='egrep --color=auto'" >> $HOME/.bash_aliases && \
    echo "alias fgrep='fgrep --color=auto'" >> $HOME/.bash_aliases && \
    echo "alias grep='grep --color=auto'" >> $HOME/.bash_aliases && \
    echo "alias ls='ls --color=auto'" >> $HOME/.bash_aliases && \
    echo "alias mv='mv -i'" >> $HOME/.bash_aliases && \
    echo "alias rm='rm -i'" >> $HOME/.bash_aliases

# set OpenMP Threads
RUN echo "export OMP_NUM_THREADS=${NUMTHREADS}" >> $HOME/.bashrc

# OpenBLAS threads should be 1 to ensure performance
RUN echo "export OPENBLAS_NUM_THREADS=${NUMTHREADS}" >> $HOME/.bashrc && \
    echo "export OPENBLAS_VERBOSE=0" >> $HOME/.bashrc

# at the end
RUN echo 'debconf debconf/frontend select Dialog' | sudo debconf-set-selections


USER root
CMD ["/usr/local/bin/start.sh"]

