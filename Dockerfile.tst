# daemon runs in the background
# run something like tail /var/log/Zentd/current to see the status
# be sure to run with volumes, ie:
# docker run -v $(pwd)/Zentd:/var/lib/Zentd -v $(pwd)/wallet:/home/zentcash --rm -ti zentcash:0.2.2
ARG base_image_version=0.10.0
FROM phusion/baseimage:$base_image_version

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ADD https://github.com/just-containers/socklog-overlay/releases/download/v2.1.0-0/socklog-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/socklog-overlay-amd64.tar.gz -C /

ARG ZENTCASH_BRANCH=master
ENV ZENTCASH_BRANCH=${ZENTCASH_BRANCH}

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      python-dev \
      gcc-4.9 \
      g++-4.9 \
      git cmake \
      libboost1.58-all-dev && \
    git clone https://github.com/Zentcash/Zent.git /src/zentcash && \
    cd /src/zentcash && \
    git checkout $ZENTCASH_BRANCH && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_CXX_FLAGS="-g0 -Os -fPIC -std=gnu++11" .. && \
    make -j$(nproc) && \
    mkdir -p /usr/local/bin && \
    cp src/Zentd /usr/local/bin/Zentd && \
    cp src/wallet-api /usr/local/bin/wallet-api && \
    cp src/zentwallet /usr/local/bin/zentwallet && \
    cp src/miner /usr/local/bin/miner && \
    strip /usr/local/bin/Zentd && \
    strip /usr/local/bin/wallet-api && \
    strip /usr/local/bin/zentwallet && \
    strip /usr/local/bin/miner && \
    cd / && \
    rm -rf /src/zentcash && \
    apt-get remove -y build-essential python-dev gcc-4.9 g++-4.9 git cmake libboost1.58-all-dev && \
    apt-get autoremove -y && \
    apt-get install -y  \
      libboost-system1.58.0 \
      libboost-filesystem1.58.0 \
      libboost-thread1.58.0 \
      libboost-date-time1.58.0 \
      libboost-chrono1.58.0 \
      libboost-regex1.58.0 \
      libboost-serialization1.58.0 \
      libboost-program-options1.58.0 \
      libicu55

# setup the Zentd service
RUN useradd -r -s /usr/sbin/nologin -m -d /var/lib/Zentd Zentd && \
    useradd -s /bin/bash -m -d /home/zentcash zentcash && \
    mkdir -p /etc/services.d/Zentd/log && \
    mkdir -p /var/log/Zentd && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/Zentd/run && \
    echo "fdmove -c 2 1" >> /etc/services.d/Zentd/run && \
    echo "cd /var/lib/Zentd" >> /etc/services.d/Zentd/run && \
    echo "export HOME /var/lib/Zentd" >> /etc/services.d/Zentd/run && \
    echo "s6-setuidgid Zentd /usr/local/bin/Zentd" >> /etc/services.d/Zentd/run && \
    chmod +x /etc/services.d/Zentd/run && \
    chown nobody:nogroup /var/log/Zentd && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/Zentd/log/run && \
    echo "s6-setuidgid nobody" >> /etc/services.d/Zentd/log/run && \
    echo "s6-log -bp -- n20 s1000000 /var/log/Zentd" >> /etc/services.d/Zentd/log/run && \
    chmod +x /etc/services.d/Zentd/log/run && \
    echo "/var/lib/Zentd true Zentd 0644 0755" > /etc/fix-attrs.d/Zentd-home && \
    echo "/home/zentcash true zentcash 0644 0755" > /etc/fix-attrs.d/zentcash-home && \
    echo "/var/log/Zentd true nobody 0644 0755" > /etc/fix-attrs.d/Zentd-logs

VOLUME ["/var/lib/Zentd", "/home/zentcash","/var/log/Zentd"]

ENTRYPOINT ["/init"]
CMD ["/usr/bin/execlineb", "-P", "-c", "emptyenv cd /home/zentcash export HOME /home/zentcash s6-setuidgid zentcash /bin/bash"]
