#!/bin/bash
# Start GeoNames server in background
lucene-geo-gazetteer -server &
echo "Started GeoNames server on port 8765"

# Wait for GeoNames server to initialize
sleep 5

# Start Tika server in background with connection to GeoNames server
cd /app/tika
echo "Starting Tika server..."
java -Dgazetteer.url=http://localhost:8765 \
     -Dtika.config=/app/tika/tika-config.xml \
     -classpath tika-server-standard-2.6.0.jar:tika-parser-nlp-package-2.6.0.jar:tika-parser-geo-package-2.6.0.jar:/app/location-ner-model:/app/geotopic-mime:/app/models/polar:/app/geotopicparser-utils/mime:/app/geotopicparser-utils/models/polar \
     org.apache.tika.server.core.TikaServerCli -h 0.0.0.0 -p 9998 &

echo "Started Tika server on port 9998"

# Keep container running
wait