
FROM ubuntu:18.04

# == Install required tools
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq && apt-get install -qq -y \
  bc \
  binutils-arm-linux-gnueabi \
  binutils-aarch64-linux-gnu \
  binutils-multiarch \
  curl \
  expect \
  git \
  maven \
  nano \
  python \
  python-dev \
  python-pip \
  python3-pip \
  scons \
  unzip \
  wget \
  zip \
  libcapstone3 \
  openjdk-8-jdk-headless \
  tzdata

RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime

# Set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# FIXME: Python stuff should be in a venv handled by .jenkins.sh
ENV PYTHON_REQS "requests PyJWT validators durations pyaxmlparser javalang capstone virtualenv"
RUN pip install  -q $PYTHON_REQS
RUN pip3 install -q $PYTHON_REQS


#Android stuff
RUN apt-get install -qq -y gradle


# 32-bit libraries
RUN dpkg --add-architecture i386 \
 && apt-get update -qq \
 && apt-get install -qq -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386

# == Set up Android NDK-related environment
ENV ANDROID_NDK_HOME /opt/android-ndk-r12
ENV PATH ${PATH}:${ANDROID_NDK_HOME}

# == Download Android NDK and install in /opt/android-ndk-r12
ENV ANDROID_NDK_PACKAGE=android-ndk-r12-linux-x86_64.zip
RUN cd /opt \
 && wget -q http://dl.google.com/android/repository/${ANDROID_NDK_PACKAGE} \
 && unzip -q ${ANDROID_NDK_PACKAGE} \
 && rm ${ANDROID_NDK_PACKAGE} \
 && test -d "${ANDROID_NDK_HOME}"


# === Install Android SDKs
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_FILENAME android-sdk_r24.3.3-linux.tgz
ENV ANDROID_SDK_URL http://dl.google.com/android/${ANDROID_SDK_FILENAME}
ENV ANDROID_API_LEVELS android-25
ENV ANDROID_BUILD_TOOLS_VERSION 25.0.3
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

RUN cd /opt && \
    wget -q ${ANDROID_SDK_URL} && \
    tar -xzf ${ANDROID_SDK_FILENAME} && \
    rm ${ANDROID_SDK_FILENAME} && \
    echo y | android update sdk --no-ui -a --filter tools,platform-tools,${ANDROID_API_LEVELS},build-tools-${ANDROID_BUILD_TOOLS_VERSION}

# Create home directory and make it writable so jenkins can invoke gradle safely
RUN mkdir $ANDROID_HOME/.android && \
	chmod 777 $ANDROID_HOME/.android

# Accept licenses before installing components, no need to echo y for each component
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
RUN yes | sdkmanager --licenses

# Platform tools
RUN sdkmanager "emulator" "tools" "platform-tools"

# SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.

# Please keep all sections in descending order!
RUN yes | sdkmanager \
    "platforms;android-28" \
    "platforms;android-27" \
    "platforms;android-26" \
    "platforms;android-25" \
    "platforms;android-24" \
    "platforms;android-23" \
    "platforms;android-22" \
    "platforms;android-21" \
    "platforms;android-19" \
    "platforms;android-17" \
    "platforms;android-15" \
    "build-tools;28.0.3" \
    "build-tools;28.0.2" \
    "build-tools;28.0.1" \
    "build-tools;28.0.0" \
    "build-tools;27.0.3" \
    "build-tools;27.0.2" \
    "build-tools;27.0.1" \
    "build-tools;27.0.0" \
    "build-tools;26.0.2" \
    "build-tools;26.0.1" \
    "build-tools;25.0.3" \
    "build-tools;24.0.3" \
    "build-tools;23.0.3" \
    "build-tools;22.0.1" \
    "build-tools;21.1.2" \
    "build-tools;19.1.0" \
    "build-tools;17.0.0" \
    "system-images;android-28;google_apis;x86" \
    "system-images;android-26;google_apis;x86" \
    "system-images;android-25;google_apis;armeabi-v7a" \
    "system-images;android-24;default;armeabi-v7a" \
    "system-images;android-22;default;armeabi-v7a" \
    "system-images;android-19;default;armeabi-v7a" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" \
    "add-ons;addon-google_apis-google-23" \
    "add-ons;addon-google_apis-google-22" \
    "add-ons;addon-google_apis-google-21"


# --- Install Gradle from PPA

# Gradle PPA
RUN apt-get update \
 && apt-get -y install gradle \
 && gradle -v

# ------------------------------------------------------
# --- Install Maven 3 from PPA

RUN apt-get purge maven maven2 \
 && apt-get update \
 && apt-get -y install maven \
 && mvn --version


# ------------------------------------------------------
