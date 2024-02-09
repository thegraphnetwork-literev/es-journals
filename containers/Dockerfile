# ref: https://github.com/mamba-org/micromamba-docker/blob/main/Dockerfile

FROM condaforge/mambaforge:latest

LABEL maintainer="Ivan Ogasawara <ivan.ogasawara@gmail.com>"
LABEL org.opencontainers.image.title="rXiv REST API"
LABEL org.opencontainers.image.authors="rXiv REST API Team"
LABEL org.opencontainers.image.source="https://github.com/xmnlab/rxiv-restapi.git"
LABEL org.opencontainers.image.version="latest"
LABEL org.opencontainers.image.description="A service for rXiv REST API, such as biorxiv and medrxiv"

# it is the default, but using it here to have it explicitly
USER root

SHELL ["/bin/bash", "-c"]

# Use bash in Dockerfile RUN commands and make sure bashrc is sourced when
# executing commands with /bin/bash -c
# Needed to have the micromamba activate command configured etc.

ENV ENV_NAME=rxiv_rest_api
ENV DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        build-essential \
        curl \
        git \
        libffi-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        locales \
        postgresql-client \
        vim && \
    rm -rf /var/lib/apt/lists/*

RUN mamba install -y poetry

RUN mkdir -p /tmp/rxivapp
COPY pyproject.toml /tmp/rxivapp/

WORKDIR /tmp/rxivapp/

# Create and copy virtual environment: Poetry is configured not to create a new
# virtual environment and necessary dependencies are installed without
# development packages

RUN poetry config virtualenvs.create false && \
    poetry install --only main --no-interaction --no-ansi --no-root

COPY . /app

WORKDIR /app/src/rxiv_rest_api

CMD ["/app/containers/entrypoint.sh", "python", "app.py"]
