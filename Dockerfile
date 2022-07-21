FROM adoptopenjdk/openjdk11:alpine AS java-builder
WORKDIR /jlink
ENV PATH $JAVA_HOME/bin:$PATH
RUN jlink --strip-debug --no-header-files --no-man-pages --compress=2 --module-path $JAVA_HOME \
    --add-modules java.base,java.desktop,java.instrument,java.management.rmi,java.naming,java.prefs,java.scripting,java.security.jgss,java.sql,jdk.httpserver,jdk.unsupported \
    --output jre-min


FROM alpine:3.15.0
USER root

RUN apk --update add --no-cache ca-certificates curl openssl binutils xz \
    && GLIBC_VER="2.28-r0" \
    && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
    && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-8.2.1%2B20180831-1-x86_64.pkg.tar.xz" \
    && GCC_LIBS_SHA256=e4b39fb1f5957c5aab5c2ce0c46e03d30426f3b94b9992b009d417ff2d56af4d \
    && ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.9-1-x86_64.pkg.tar.xz" \
    && ZLIB_SHA256=bb0959c08c1735de27abf01440a6f8a17c5c51e61c3b4c707e988c906d3b7f67 \
    && curl -Ls https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/${GLIBC_VER}.apk \
    && apk add /tmp/${GLIBC_VER}.apk \
    && curl -Ls ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
    && echo "${GCC_LIBS_SHA256}  /tmp/gcc-libs.tar.xz" | sha256sum -c - \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
    && curl -Ls ${ZLIB_URL} -o /tmp/libz.tar.xz \
    && echo "${ZLIB_SHA256}  /tmp/libz.tar.xz" | sha256sum -c - \
    && mkdir /tmp/libz \
    && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
    && apk del binutils \
    && rm -rf /tmp/${GLIBC_VER}.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

COPY --from=java-builder /jlink/jre-min /opt/jre-min


ARG JAR_FILE=target/*.jar

COPY ${JAR_FILE} app.jar
ENV PATH /opt/jre-min/bin:$PATH

WORKDIR /
VOLUME [ "/tmp" ]
CMD /bin/sh -c "java -XX:MinHeapFreeRatio=${JAVA_MIN_HEAP_FREE_RATIO:=10} -XX:MaxHeapFreeRatio=${JAVA_MAX_HEAP_FREE_RATIO:=70} -XX:CompressedClassSpaceSize=${JAVA_COMPRESSED_CLASS_SPACE_SIZE:=64m} -XX:ReservedCodeCacheSize=${JAVA_RESERVED_CODE_CACHE_SIZE:=64m} -XX:MaxMetaspaceSize=${JAVA_MAX_META_SPACE_SIZE:=256m} -Xms${JAVA_XMS:=256m} -Xmx${JAVA_XMX:=450m} -Djava.security.egd=file:/dev/./urandom -Dspring.profiles.active=${JAVA_PROFILE:=default} -Dspring.profiles.default=${JAVA_PROFILE:=default} -Dfile.encoding=UTF-8 -jar /app.jar ${JAVA_ARGS} "
