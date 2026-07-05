FROM postgres:17

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --break-system-packages patroni[etcd3] psycopg2-binary

RUN mkdir -p /data/patroni /etc/patroni \
    && chown postgres:postgres /data/patroni

COPY patroni.yml /etc/patroni/config.yml
COPY post_bootstrap.sh /etc/patroni/post_bootstrap.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /etc/patroni/post_bootstrap.sh

USER postgres
ENTRYPOINT ["/entrypoint.sh"]
