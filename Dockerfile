FROM python:3.12-alpine
COPY ./src /tmp/src
RUN ls /tmp/src
RUN pip install --no-cache /tmp/src
CMD ["python3", "-m", "dumass_dns", "refresh"]

