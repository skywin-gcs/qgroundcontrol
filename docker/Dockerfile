# QGroundControl Docker Container
# Supports: Ubuntu 22.04/24.04, ARM64 (Jetson), x86_64

ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

LABEL maintainer="QGroundControl Docker Build"
LABEL description="QGroundControl with YOLO object detection for UAV ground control"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV QT_VERSION=6.10.2
ENV QT_DIR=/opt/qt/${QT_VERSION}/gcc_64
ENV PATH="${QT_DIR}/bin:${PATH}"

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build git wget curl \
    libgl1-mesa-dev libvulkan-dev libxkbcommon-x11-dev \
    libopencv-dev libgstreamer1.0-dev libsdl2-dev \
    libbluetooth-dev libusb-1.0-0-dev \
    libpulse-dev libasound2-dev \
    python3-pip locales \
    && rm -rf /var/lib/apt/lists/*

# Install Qt6
RUN pip3 install --break-system-packages aqtinstall || pip3 install aqtinstall && \
    aqt install-qt linux desktop ${QT_VERSION} gcc_64 --outputdir /opt/qt \
    --modules qtcharts qtlocation qtpositioning qtmultimedia qtserialport \
    qtconnectivity qtspeech qt5compat qtquick3d qtshadertools qtlanguageserver && \
    rm -rf /opt/qt/${QT_VERSION}/gcc_64/doc /opt/qt/${QT_VERSION}/gcc_64/examples

# Build QGC
WORKDIR /app
COPY . /app/qgroundcontrol/
RUN mkdir -p /app/qgroundcontrol/build-docker && cd /app/qgroundcontrol/build-docker && \
    cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${QT_DIR}" \
    -DCMAKE_INSTALL_PREFIX=/app/qgroundcontrol/install && \
    ninja -j$(nproc) && ninja install

# Runtime stage
FROM ${BASE_IMAGE} as runtime
ENV DEBIAN_FRONTEND=noninteractive
ENV QT_DIR=/opt/qt/6.10.2/gcc_64
ENV PATH="${QT_DIR}/bin:${PATH}"
ENV QT_QPA_PLATFORM=xcb

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx libvulkan1 libopencv-core4.5d libgstreamer1.0-0 \
    libsdl2-2.0-0 libusb-1.0-0 libpulse0 locales \
    && rm -rf /var/lib/apt/lists/*

COPY --from=0 /opt/qt /opt/qt
COPY --from=0 /app/qgroundcontrol/install /app/qgroundcontrol

WORKDIR /app/qgroundcontrol
RUN useradd -m -s /bin/bash qgcuser && chown -R qgcuser:qgcuser /app/qgroundcontrol

EXPOSE 14550/udp 14551/udp 5760/tcp 8080/tcp
USER qgcuser
CMD ["/app/qgroundcontrol/bin/QGroundControl"]
