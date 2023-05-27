FROM python:alpine

RUN mkdir /config
RUN mkdir /code

# Gunicorn configuration
ADD gunicorn.conf /config

# Flask app
ADD server.py /code
ADD requirements.txt /code
RUN pip3 install -r /code/requirements.txt

# app, certificate watcher and envoy
CMD ["gunicorn", "--config", "/config/gunicorn.conf", "--pythonpath", "/code", "server:app"]
