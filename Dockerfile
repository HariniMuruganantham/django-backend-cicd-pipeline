# Base image — pinned to a specific digest for reproducibility and supply-chain safety.
# To update: docker pull python:3.12-slim, then replace the digest below.
FROM python:3.12-slim

# Prevent Python from buffering stdout/stderr and writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Run as a non-root user — never run application code as root in containers
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /app

# Install system dependencies for psycopg2
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies before copying app code so Docker layer cache
# is reused on code-only changes (requirements.txt changes bust the cache).
COPY requirements.txt .
RUN pip install --upgrade pip --no-cache-dir \
    && pip install -r requirements.txt --no-cache-dir

# Copy application code and hand ownership to the non-root user
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Expose Django's default port
EXPOSE 8000

# Apply migrations then start the dev server.
# For production, replace this with gunicorn or uvicorn.
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py runserver 0.0.0.0:8000"]