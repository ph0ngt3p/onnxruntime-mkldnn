FROM python:3.6.8-slim-stretch

LABEL maintainer=zun1903@gmail.com

ENV PATH "/cmake-3.14.3-Linux-x86_64/bin:$PATH"

# Build onnxruntime with MKLDNN
RUN set -ex \
    \
    && savedAptMark="$(apt-mark showmanual)" \
    && apt-get update && apt-get install -y --no-install-recommends \
    wget \
    git \
    build-essential \
    \
    && pip install numpy==1.16.2 \
    && wget --quiet https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3-Linux-x86_64.tar.gz \
    && tar zxf cmake-3.14.3-Linux-x86_64.tar.gz \
    && rm -rf cmake-3.14.3-Linux-x86_64.tar.gz \
    \
    && git clone --single-branch --branch rel-1.0.0 --recursive https://github.com/microsoft/onnxruntime.git onnxruntime \
    && cd /onnxruntime \
    && ./build.sh --config Release --parallel --update --build --use_openmp --use_mkldnn --use_mklml --build_wheel \
    && cd build/Linux/Release/ \
    && python ../../../setup.py install \
    \
    && apt-mark auto '.*' > /dev/null \
    && apt-mark manual $savedAptMark \
    && find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
    | awk '/=>/ { print $(NF-1) }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /onnxruntime /cmake-3.14.3-Linux-x86_64
