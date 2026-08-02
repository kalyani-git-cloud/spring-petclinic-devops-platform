# Monitoring

## Overview

This directory contains the monitoring configuration for the Spring PetClinic DevOps project.

## Tools Used

- Prometheus
- Grafana

## Purpose

The monitoring solution provides visibility into infrastructure and application health.

Metrics include:

- CPU Usage
- Memory Usage
- Pod Status
- HTTP Requests
- Application Availability

## Directory Structure

monitoring/

├── prometheus/

│ └── prometheus.yml

├── grafana/

│ └── datasource.yml

└── README.md

## Prometheus

Prometheus is responsible for collecting metrics from:

- Prometheus Server
- Spring PetClinic Application
- Kubernetes Cluster

## Grafana

Grafana connects to Prometheus and provides dashboards for:

- CPU
- Memory
- Pods
- Requests

## Deliverable

Dashboards showing infrastructure and application health.