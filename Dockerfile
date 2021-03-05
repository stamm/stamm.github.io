FROM alpine:3.12.0 as blog-builder

ENV HUGO_VERSION 0.72.0
WORKDIR /blog
RUN apk add --update --no-cache tar wget ca-certificates
RUN wget -q https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz && \
  mkdir /hugo && \
  tar xzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /hugo
COPY . /blog
RUN /hugo/hugo --theme=hugo-theme-minos


FROM nginx:1.19.0
MAINTAINER Rustam Zagirov <stammru@gmail.com>
ARG release

RUN rm /etc/nginx/conf.d/default.conf
COPY deploy/site.conf /etc/nginx/conf.d/site.conf

COPY --from=blog-builder /blog/public /var/www/

