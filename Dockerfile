# Use an official Maven image to build the project
FROM maven:3.8.8-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Clone the lucene-geo-gazetteer repository
RUN git clone https://github.com/chrismattmann/lucene-geo-gazetteer.git

# Build the project
WORKDIR /app/lucene-geo-gazetteer
RUN mvn install assembly:assembly

# Use a lightweight image for the runtime
FROM eclipse-temurin:17-jre

# Set working directory
WORKDIR /app

# Install required tools
RUN apt-get update && apt-get install -y curl unzip git

# Copy the built project from the builder stage
COPY --from=builder /app/lucene-geo-gazetteer /app/lucene-geo-gazetteer

# Add the bin directory to PATH
ENV PATH="/app/lucene-geo-gazetteer/src/main/bin:$PATH"

# Ensure the lucene-geo-gazetteer binary is executable
RUN chmod +x /app/lucene-geo-gazetteer/src/main/bin/lucene-geo-gazetteer

# Download and prepare GeoNames data
WORKDIR /app/lucene-geo-gazetteer
RUN curl -O http://download.geonames.org/export/dump/allCountries.zip && \
    unzip allCountries.zip && \
    ./src/main/bin/lucene-geo-gazetteer -i geoIndex -b allCountries.txt

# Download necessary Tika JAR files
WORKDIR /app/tika
RUN curl -L -O https://repo1.maven.org/maven2/org/apache/tika/tika-server-standard/2.6.0/tika-server-standard-2.6.0.jar && \
    curl -L -O https://repo1.maven.org/maven2/org/apache/tika/tika-parser-nlp-package/2.6.0/tika-parser-nlp-package-2.6.0.jar && \
    ls -la && \
    # Verify that the JAR files are not empty
    [ -s tika-server-standard-2.6.0.jar ] || exit 1 && \
    [ -s tika-parser-nlp-package-2.6.0.jar ] || exit 1

# Add additional Tika parser for geo capabilities
RUN curl -L -O https://repo1.maven.org/maven2/org/apache/tika/tika-parser-geo-package/2.6.0/tika-parser-geo-package-2.6.0.jar && \
    [ -s tika-parser-geo-package-2.6.0.jar ] || exit 1

# Create Tika config file
COPY tika-config.xml /app/tika/tika-config.xml

# Clone geotopicparser-utils (needed for proper polar data processing)
WORKDIR /app
RUN git clone https://github.com/chrismattmann/geotopicparser-utils.git

# Copy the polar models to the correct location
RUN mkdir -p /app/models/polar
WORKDIR /app/geotopicparser-utils
RUN if [ -d models/polar ]; then cp -r models/polar/* /app/models/polar/; fi

# Setup location NER model
WORKDIR /app/location-ner-model
RUN curl -O https://opennlp.sourceforge.net/models-1.5/en-ner-location.bin

# Setup geotopic MIME types
WORKDIR /app/geotopic-mime
RUN mkdir -p org/apache/tika/mime && \
    curl -O https://raw.githubusercontent.com/chrismattmann/geotopicparser-utils/master/mime/org/apache/tika/mime/custom-mimetypes.xml && \
    mv custom-mimetypes.xml org/apache/tika/mime/

# Copy the start-servers.sh script into the image
COPY start-servers.sh /app/start-servers.sh

# Make the script executable
RUN chmod +x /app/start-servers.sh

# Create a debug script
RUN echo '#!/bin/bash\n\
echo "Listing all directories:"\n\
find /app -type d | sort\n\n\
echo "Checking JAR files:"\n\
ls -la /app/tika\n\n\
echo "Testing Tika server start:"\n\
cd /app/tika\n\
java -jar tika-server-standard-2.6.0.jar --help\n\
' > /app/debug.sh && chmod +x /app/debug.sh

# Expose the ports for the servers
EXPOSE 8765 9998

# Use the start-servers.sh script to start the servers
CMD ["/app/start-servers.sh"]