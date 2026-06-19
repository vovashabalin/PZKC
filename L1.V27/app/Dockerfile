# Production image used by Laboratory work 2 and Laboratory work 3.
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/mywebapp

COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt \
    && addgroup --system app \
    && adduser --system --ingroup app --home /nonexistent --no-create-home app

COPY mywebapp ./mywebapp
COPY migrate.py wsgi.py ./
COPY docker-entrypoint.sh ./
RUN chmod 0755 docker-entrypoint.sh \
    && chown -R app:app /opt/mywebapp

USER app
EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=5 \
  CMD python -c "from urllib.request import urlopen; urlopen('http://127.0.0.1:3000/health/ready', timeout=2).read()" || exit 1

ENTRYPOINT ["./docker-entrypoint.sh"]
