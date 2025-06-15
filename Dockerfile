FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y util-linux procps bash && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["nsenter", "--target", "1", "--mount", "--uts", "--ipc", "--net", "--pid", "--", "bash"]


