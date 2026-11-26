# Use the official Python slim image, pinned to a Debian release (13, trixie) so that a new Debian
# release cannot silently change the build.
FROM python:3.13-slim-trixie

# Install dependencies for SQLCMD - msodbcsql and mssql-tools require curl, gnupg, and such.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    bash \
    csvkit \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Add the Microsoft repository for mssql-tools. Microsoft's packages-microsoft-prod package installs the
# source list together with the signing key that list needs (the Debian 13 repository uses a newer key).
# Keep the Debian number in this URL in step with the base image above.
RUN curl -fsSL -o /tmp/packages-microsoft-prod.deb https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb \
  && dpkg -i /tmp/packages-microsoft-prod.deb \
  && rm /tmp/packages-microsoft-prod.deb

# Update package lists again and install mssql-tools and msodbcsql17.
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
    mssql-tools \
    msodbcsql17 \
  && rm -rf /var/lib/apt/lists/*

# Add the Microsoft SQL Server tools to the PATH.
ENV PATH="/opt/mssql-tools/bin:${PATH}"


# Optionally, install any Python dependencies.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code.
COPY ./app /app
WORKDIR /app

# Set the entrypoint to a bash script or the Python interpreter.
ENTRYPOINT ["bash", "entry_point.sh"]
