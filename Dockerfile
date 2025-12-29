FROM python:3.12-alpine
COPY ./src /tmp/src
RUN pip install --no-cache /tmp/src
CMD ["python3", "-m", "dumbass_dns.refresh"]

