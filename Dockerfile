FROM ubuntu:18.04 as builder

# Allows us to auto-discover the latest release from the repo
ARG ZentCashFoundation/Zent
ENV REPO=${REPO}

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      python-dev \
      gcc-8 \
      g++-8 \
      git cmake \
      libboost-all-dev && \
      git clone https://github.com/ZentCashFoundation/Zent.git /opt/Zent && \
      cd /opt/Zent && \
      mkdir build && \
      cd build && \
      cmake .. && \
      make

FROM keymetrics/pm2:latest-stretch

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/ZentCashFoundation/Zent.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"

RUN mkdir -p /usr/local/bin
WORKDIR /usr/local/bin
COPY --from=builder /opt/Zent/build/src/Zentd .
COPY --from=builder /opt/Zent/build/src/Zent-service .
COPY --from=builder /opt/Zent/build/src/zentwallet .
COPY --from=builder /opt/Zent/build/src/miner .
COPY --from=builder /opt/Zent/build/src/wallet-api .
COPY --from=builder /opt/Zent/build/src/cryptotest .
COPY --from=builder /opt/Zent/build/src/zentwallet-beta .
RUN mkdir -p /var/lib/zentd
WORKDIR /var/lib/zentd
ADD https://github.com/ZentCashFoundation/checkpoints/raw/master/checkpoints.csv /var/lib/zentd
ENTRYPOINT ["/usr/local/bin/Zentd"]
CMD ["--no-console","--data-dir","/var/lib/Zentd","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","21698","--p2p-bind-port","21688","--enable-cors=*","--enable-blockexplorer","--load-checkpoints","/var/lib/zentd/checkpoints.csv"]