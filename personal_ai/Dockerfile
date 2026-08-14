FROM pgvector/pgvector:pg16
RUN mkdir -p /docker-entrypoint-initdb.d
COPY init.sql /docker-entrypoint-initdb.d/
