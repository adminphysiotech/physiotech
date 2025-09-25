# Use an official Python runtime as a parent image (Bullseye version)
FROM python:3.9-bullseye

# Set the working directory in the container
WORKDIR /app

# Install build dependencies required for some Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    python3-dev \
    # Remove default-libmysqlclient-dev unless you explicitly need MySQL client libs
    # default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy the current directory contents into the container at /app
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose the port your FastAPI app runs on
EXPOSE 8080

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
