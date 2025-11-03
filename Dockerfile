# Base image
FROM python:3.12-slim

# Prevent Python from buffering output & writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Working directory
WORKDIR /app

# Install dependencies for PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev gcc \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy all project files
COPY . .

# Expose Django default port
EXPOSE 8000

# Default command: apply migrations and run server
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py runserver 0.0.0.0:8000"]
