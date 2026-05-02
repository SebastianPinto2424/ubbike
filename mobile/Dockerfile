FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://localhost:3000
RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginxinc/nginx-unprivileged:1.27-alpine

ARG API_BASE_URL=http://localhost:3000
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN sed -i "s#__API_BASE_URL__#${API_BASE_URL}#g" /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080
