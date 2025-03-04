# FROM nicolaka/netshoot:latest AS base
FROM debian:bookworm-slim AS base

# set environment variables here with 'ENV VAR=value'
# this allows dynamic customization of container behavior

# address of the PLC OPC UA server
# ENV OPCUA_SERVER_ADDRESS=

# update index and install packages if necessary with
# configure the main environment for build and release here
ARG YOUR_ENV
ENV YOUR_ENV=${YOUR_ENV} \
  PYTHONFAULTHANDLER=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONHASHSEED=random \
  PIP_NO_CACHE_DIR=off \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  SHELL="/bin/bash" 

# we might need to move this to the action script
SHELL ["/bin/bash", "-c"]

# venv is a needed dependency for poetry and the installer to resove dependencies outside of poetry
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3.11 \
    libssl-dev \
    libsqlite3-dev \
    git \
    python3.11-venv 


# run the scripts within the exploit folder to keep everything clean
WORKDIR /exploit
RUN git clone https://github.com/claroty/opcua-exploit-framework.git && \
    ls && \
    cd opcua-exploit-framework && \
    ls && \
    python3.11 -m venv venv && \ 
    source ./venv/bin/activate && \ 
    pip install -r requirements.txt

# arguments passed to entrypoint, ensures that environment variables are set
# these will need more work and exporting, to allow for handling input and output
# of github action code 
WORKDIR opcua-exploit-framework
ARG TARGET_IP=opc-testserver
ARG DEFAULT_OPC_PORT=49947
ARG DEFAULT_ENDPOINT="/freeopcua/server/"
ENV ENV_TARGET_IP=$TARGET_IP
ENV ENV_DEFAULT_OPC_PORT=$DEFAULT_OPC_PORT
ENV ENV_DEFAULT_ENDPOINT=$DEFAULT_ENDPOINT

# Github runner require a distinctive cd step inside the docker command, since the workdir is per default
# overriden to /github/workspace and mounted against the current repository
# this change should work with both cases thou
CMD ["/bin/bash", "-c", "cd /exploit/opcua-exploit-framework && source ./venv/bin/activate && \
        python3.11 main.py opcua-python $ENV_TARGET_IP $ENV_DEFAULT_OPC_PORT $ENV_DEFAULT_ENDPOINT sanity"]

