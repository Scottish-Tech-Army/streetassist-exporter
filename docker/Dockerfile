# Use the official Python slim image.
FROM python:3.10-slim

# Install dependencies for SQLCMD - msodbcsql and mssql-tools require curl, gnupg, and such.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    bash \
  && rm -rf /var/lib/apt/lists/*

# Add the Microsoft repository keys and sources for mssql-tools.
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Update package lists again and install mssql-tools and msodbcsql17.
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
    mssql-tools \
    msodbcsql17 \
  && ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd \
  && rm -rf /var/lib/apt/lists/*

# Optionally, install any Python dependencies.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your application code.
COPY ./app /app
WORKDIR /app

# Set the entrypoint to a bash script or the Python interpreter.
ENTRYPOINT ["bash", "entry_point.sh"]
#CMD ["python3", "--version"]
