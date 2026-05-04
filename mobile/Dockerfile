FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://localhost:3000
RUN flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginxinc/nginx-unprivileged:1.27-alpine

ARG API_BASE_URL=http://localhost:3000
ARG CSP_CONNECT_SRC
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN CSP_VALUE="${CSP_CONNECT_SRC:-'self' ${API_BASE_URL}}" && \
    sed -i "s#__CSP_CONNECT_SRC__#${CSP_VALUE}#g" /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080
