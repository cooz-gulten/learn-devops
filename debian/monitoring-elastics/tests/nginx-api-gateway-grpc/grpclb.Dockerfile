
FROM nginx:1.18.0

# RUN  touch /var/run/nginx.pid && \
#      chown -R nginx:nginx /var/cache/nginx /var/run/nginx.pid
# USER nginx

RUN chmod -R 755 /var/log/nginx

COPY conf/grpc_gateway.okd-afandy-local.conf /etc/nginx/conf.d/
COPY conf/errors.grpc_conf /etc/nginx/conf.d/