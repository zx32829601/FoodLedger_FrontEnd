# syntax=docker/dockerfile:1

FROM debian:12.14-slim AS build

ARG FLUTTER_VERSION=3.44.7
ARG FLUTTER_SDK_SHA256=a0edd646c159c0e816788c0e46a4f071199c1320495898f5a679599b583a05a4
ARG FOOD_LEDGER_API_BASE_URL
ARG NOTO_SANS_TC_COMMIT=f8d157532fbfaeda587e826d4cd5b21a49186f7c
ARG NOTO_SANS_TC_SHA256=ac091cc8cd19e848202afc8fe6d3809b4526c8fdbdb4be82da20c4f785949591
ARG NOTO_SANS_TC_LICENSE_COMMIT=7ff85c87f93ea6cca5f41c69f2e4edcb90240f26
ARG NOTO_SANS_TC_LICENSE_SHA256=1c05c68c34f9708415aada51f17e1b0092d2cea709bf4a94cd38114f9e73d7d9

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --location --silent --show-error \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        --output /tmp/flutter.tar.xz \
    && echo "${FLUTTER_SDK_SHA256}  /tmp/flutter.tar.xz" | sha256sum --check --strict - \
    && tar --extract --xz --file /tmp/flutter.tar.xz --directory /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics \
    && flutter precache --web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN mkdir -p web/fonts \
    && curl --fail --location --silent --show-error \
        "https://raw.githubusercontent.com/notofonts/noto-cjk/${NOTO_SANS_TC_COMMIT}/Sans/Variable/TTF/Subset/NotoSansTC-VF.ttf" \
        --output web/fonts/NotoSansTC-VF.ttf \
    && echo "${NOTO_SANS_TC_SHA256}  web/fonts/NotoSansTC-VF.ttf" | sha256sum --check --strict - \
    && curl --fail --location --silent --show-error \
        "https://raw.githubusercontent.com/google/fonts/${NOTO_SANS_TC_LICENSE_COMMIT}/ofl/notosanstc/OFL.txt" \
        --output web/fonts/NotoSansTC-OFL.txt \
    && echo "${NOTO_SANS_TC_LICENSE_SHA256}  web/fonts/NotoSansTC-OFL.txt" | sha256sum --check --strict -

RUN test -n "${FOOD_LEDGER_API_BASE_URL}" \
    && flutter build web \
        --release \
        --dart-define="FOOD_LEDGER_API_BASE_URL=${FOOD_LEDGER_API_BASE_URL}"

FROM nginx:1.30.4-alpine3.24 AS runtime

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1/health || exit 1
