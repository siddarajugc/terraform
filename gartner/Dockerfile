FROM hashicorp/terraform:latest

ENV PYTHONUNBUFFERED=1
RUN apk add --no-cache --upgrade bash && \
    apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python && \
    apk add --no-cache py-pip ca-certificates && pip install s3cmd && \
    python3 -m ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools && \
    pip3 install python-dateutil


WORKDIR /availability

ENTRYPOINT ["/availability/terraform.sh"]
