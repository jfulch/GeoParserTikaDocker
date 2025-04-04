# GeoParserTika Docker

A containerized solution for geographic entity extraction from text documents using Apache Tika and GeoNames gazetteer.

## Docker Details
- https://hub.docker.com/r/jfulch/geotopic-parser

```bash
docker pull jfulch/geotopic-parser
```

## Overview

This Docker image provides a complete environment for parsing documents and extracting geographic information. It combines two powerful services:

1. GeoNames Gazetteer Server (port 8765) - For location name lookup and geocoding
2. Apache Tika Server (port 9998) - For document parsing with geo-entity extraction capabilities

## Features

- Extract geographic entities (locations) from text documents
- Resolve location names to specific geographic coordinates
- Process various document formats including .geot (geotopic) files
- Identify primary and secondary location mentions in text

## Prerequisites
- Docker installed on your system
- At least 4GB RAM available for Docker
- 8GB+ disk space (for GeoNames database)

## Platform Compatibility

This Docker image supports multiple architectures:
- ARM64 (Apple Silicon Macs)
- AMD64 (Intel Macs and most Linux/Windows systems)

Docker will automatically pull the correct version for your system architecture.

## Quick Start
Pull from Docker Hub
```bash
docker pull jfulch/geotopic-parser:latest
docker run -p 8765:8765 -p 9998:9998 jfulch/geotopic-parser:latest
```
or build locally
```bash
git clone https://github.com/jfulch/GeoParserTikaDocker.git
cd GeoParserTikaDocker
docker build -t geotopic-parser .
docker run -p 8765:8765 -p 9998:9998 geotopic-parser
```

## Usage Examples
1. Search for a Location using GeoNames Server
```bash
curl "http://localhost:8765/api/search?s=New+York"
```
Example response:
```json
{"New York":[{"name":"New York","countryCode":"US","admin1Code":"NY","admin2Code":"","latitude":43.00035,"longitude":-75.4999}]}
```
2. Check if Tika Server is Running
```bash
curl "http://localhost:9998/tika"
```
Expected Response:
```
This is Tika Server (Apache Tika 2.6.0).
```
3. Process a Geotopic File
```bash
curl -T your_file.geot -H "Content-Type: application/geotopic" -H "Content-Disposition: attachment; filename=file.geot" http://localhost:9998/rmeta
```
Example resposne:
```json
[
    {
        "Geographic_LONGITUDE": "105.0",
        "Geographic_NAME": "People's Republic of China",
        "X-TIKA:Parsed-By": [
            "org.apache.tika.parser.DefaultParser",
            "org.apache.tika.parser.geo.GeoParser"
        ],
        "resourceName": "file.geot",
        "Optional_NAME1": "United States",
        "Optional_LATITUDE1": "39.76",
        "Optional_LONGITUDE1": "-98.5",
        "X-TIKA:parse_time_millis": "281",
        "Geographic_LATITUDE": "35.0",
        "Content-Type": "application/geotopic"
    }
]
```

## Components
This Docker image includes:

- lucene-geo-gazetteer: A Lucene-based gazetteer service
- Apache Tika 2.6.0: Document parsing and metadata extraction
- GeoTopicParser: Location extraction capabilities for documents
- OpenNLP models: For named entity recognition
- GeoNames database: For location name resolution

## File Structure
Key locations in the container:

- /app/lucene-geo-gazetteer: GeoNames server
- /app/tika: Tika server and JAR files
- /app/models/polar: Polar region specific models
- /app/location-ner-model: Location named entity recognition models
- /app/geotopic-mime: Custom MIME type definitions

## Troubleshooting
If you encourater issues:
1. Run the included debug script:
```bash
docker exec -it <container_id> /app/debug.sh
```
2. Check container logs
```bash
docker logs <container_id>
```
