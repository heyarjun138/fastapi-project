# Build a small image
FROM python:3.11-slim

WORKDIR /app
COPY app/dependencies.txt /app/

# Installing the dependencies
RUN pip install --no-cache-dir -r dependencies.txt

COPY app/ /app/

# Uvicorn runs FastAPI on 0.0.0.0:8000
EXPOSE 8000
ENV LOG_LEVEL=INFO
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
