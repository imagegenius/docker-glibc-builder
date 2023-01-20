# docker-glibc-builder

[![Jenkins Build](https://img.shields.io/jenkins/build?labelColor=555555&logoColor=ffffff&style=for-the-badge&jobUrl=https%3A%2F%2Fci.imagegenius.io%2Fjob%2FTools%2Fjob%2Fdocker-glibc-builder%2F&logo=jenkins)](https://ci.imagegenius.io/job/Tools/job/docker-glibc-builder/)

This is a modified version of [sgerrand/docker-glibc-builder](https://github.com/sgerrand/docker-glibc-builder) that automatically builds a glibc binary package for `x86_64` AND `aarch64` for use in alpine docker images.

These binaries are then used by [imagegenius/aports](https://github.com/imagegenius/aports) to build glibc packages for `x86_64` and `aarch64` and are available in a [docker baseimage](https://github.com/imagegenius/docker-baseimage-alpine-glibc) and as alpine packages in the [imagegenius repo](https://packages.imagegenius.io/).
