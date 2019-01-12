FROM busybox

EXPOSE 8080
RUN mkdir -p /workdir
ADD healthz /workdir
WORKDIR /workdir
CMD ./healthz