FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

RUN apt-get update && apt-get upgrade -y --allow-unauthenticated

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && apt-get upgrade -y --allow-unauthenticated && \
    apt-get install -y --allow-unauthenticated \
        build-essential \
        cmake \
        cuda-drivers \
        curl \
        git \
        libfreetype6-dev \
        libpng12-dev \
        libssl-dev \
        libxpm-dev \
        libzmq3-dev \
        module-init-tools \
        openssh-client \
        openssh-server \
        pkg-config \
        python \
        python-dev \
        python-tk \
        python3 \
        python3-dev \
        python3-tk \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        openjdk-8-jdk \
        openjdk-8-jre-headless \
        vim \
        wget \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# bazel is required for some TensorFlow projects
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" >/etc/apt/sources.list.d/bazel.list && \
    curl https://bazel.build/bazel-release.pub.gpg | apt-key add -

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated \
        bazel

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        pandas \
        Pillow \
        scipy \
        sklearn \
        && \
    python -m ipykernel.kernelspec

RUN echo "/usr/local/cuda/lib64/" >/etc/ld.so.conf.d/cuda.conf

# For CUDA profiling, TensorFlow requires CUPTI.
RUN echo "/usr/local/cuda/extras/CUPTI/lib64/" >>/etc/ld.so.conf.d/cuda.conf

# Install TensorFlow GPU version.
RUN pip uninstall tensorflow-gpu || true
RUN pip install --upgrade tensorflow-gpu==1.10

# keras
RUN pip install --upgrade keras

#############################
# now do the same for python3

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

RUN pip3 --no-cache-dir install \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        pandas \
        Pillow \
        scipy \
        sklearn \
        && \
    python3 -m ipykernel.kernelspec

# Install TensorFlow GPU version.
RUN pip3 uninstall tensorflow-gpu || true
RUN pip3 install --upgrade tensorflow-gpu==1.10

# keras
RUN pip3 install --upgrade keras

#############################

# make sure we have a way to bind host provided libraries
# see https://github.com/singularityware/singularity/issues/611
RUN mkdir -p /host-libs /etc/OpenCL/vendors && \
    echo "/host-libs/" >/etc/ld.so.conf.d/000-host-libs.conf

# required directories
RUN mkdir -p /cvmfs


# Required to get nv Singularity option working
RUN touch /bin/nvidia-smi
RUN chmod +x /bin/nvidia-smi
RUN mkdir -p /.singularity.d/libs

# root
RUN cd /opt && \
    wget -nv https://root.cern.ch/download/root_v6.10.02.Linux-ubuntu16-x86_64-gcc5.4.tar.gz && \
    tar xzf root_v6.10.02.Linux-ubuntu16-x86_64-gcc5.4.tar.gz && \
    rm -f root_v6.10.02.Linux-ubuntu16-x86_64-gcc5.4.tar.gz

# xrootd
RUN cd /opt && \
    wget http://xrootd.org/download/v4.7.1/xrootd-4.7.1.tar.gz && \
    tar xzf xrootd-4.7.1.tar.gz && \
    cd xrootd-4.7.1 && \
    mkdir build && \
    cd  build && \
    cmake /opt/xrootd-4.7.1 -DCMAKE_INSTALL_PREFIX=/opt/xrootd -DENABLE_PERL=FALSE && \
    make && \
    make install && \
    cd /opt && \
    rm -rf xrootd-4.7.1.tar.gz xrootd-4.7.1

# stashcp
RUN cd /opt && \
    git clone https://github.com/opensciencegrid/StashCache.git

# build info
RUN echo "Timestamp:" `date --utc` | tee /image-build-info.txt

