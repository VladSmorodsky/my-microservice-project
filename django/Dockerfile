FROM python:3.12-slim

WORKDIR /app

# Environment variables for Python:
# PYTHONDONTWRITEBYTECODE - don't create .pyc files
# PYTHONUNBUFFERED - output logs immediately (don't buffer)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "docker_project.wsgi:application"]