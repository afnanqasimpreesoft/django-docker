# Base stage with Python
FROM python:3.11-alpine AS base

# Builder stage to install dependencies
FROM base AS builder

RUN apk update && apk --no-cache add python3-dev libpq-dev && mkdir /install
WORKDIR /install
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Final stage
FROM base

# ARGs for non-sensitive data
ARG USER=user
ARG USER_UID=1001
ARG PROJECT_NAME=website
ARG GUNICORN_PORT=8000
ARG GUNICORN_WORKERS=2
ARG GUNICORN_TIMEOUT=60
ARG GUNICORN_LOG_LEVEL=info
ARG DJANGO_BASE_DIR=/usr/src/$PROJECT_NAME
ARG DJANGO_STATIC_ROOT=/var/www/static
ARG DJANGO_MEDIA_ROOT=/var/www/media
ARG DJANGO_SQLITE_DIR=/sqlite

# Environment variables (non-sensitive)
ENV \
    USER=$USER \
    USER_UID=$USER_UID \
    PROJECT_NAME=$PROJECT_NAME \
    GUNICORN_PORT=$GUNICORN_PORT \
    GUNICORN_WORKERS=$GUNICORN_WORKERS \
    GUNICORN_TIMEOUT=$GUNICORN_TIMEOUT \
    GUNICORN_LOG_LEVEL=$GUNICORN_LOG_LEVEL \
    DJANGO_BASE_DIR=$DJANGO_BASE_DIR \
    DJANGO_STATIC_ROOT=$DJANGO_STATIC_ROOT \
    DJANGO_MEDIA_ROOT=$DJANGO_MEDIA_ROOT \
    DJANGO_SQLITE_DIR=$DJANGO_SQLITE_DIR

# Copy dependencies from builder
COPY --from=builder /install /usr/local
COPY docker-entrypoint.sh /
COPY docker-cmd.sh /
COPY $PROJECT_NAME $DJANGO_BASE_DIR

# Set up user permissions
RUN chmod +x /docker-entrypoint.sh /docker-cmd.sh && \
    apk --no-cache add su-exec libpq-dev && \
    mkdir -p $DJANGO_STATIC_ROOT $DJANGO_MEDIA_ROOT $DJANGO_SQLITE_DIR && \
    adduser -s /bin/sh -D -u $USER_UID $USER && \
    chown -R $USER:$USER $DJANGO_BASE_DIR $DJANGO_STATIC_ROOT $DJANGO_MEDIA_ROOT $DJANGO_SQLITE_DIR

WORKDIR $DJANGO_BASE_DIR
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/docker-cmd.sh"]

EXPOSE $GUNICORN_PORT
