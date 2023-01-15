# Vite React on GCP CDN

## Description

The project demonstrates deployment of a Vite React Application on Google Cloud Platform CDN. There are 2 implementations
a. Deployment using a Bash script
b. Deployment using Terraform

### Requirements

- Google Cloud Account with owner permissions.
- Install gcloud and terraform CLI on local machine.

### Authentication commands to GCP for running commands on CL

- gcloud init
- gcloud auth application-default login

## Inputs

- DOMAIN_NAME
- PROJECT_ID
- APP_NAME

## Result

- CDN that provides React app globally
- Nameservers for CDN to link a URL.

## Deployment using bash script

- Single script for complete deployment
- Creates project if not already found.
- Verifies if website is running on CDN IP address and Domain "preciso.in"
- Provide inputs in parameters-deploy.sh

## Deployment using Terraform

- Project_id should be of an existing project
- Run make file target "deploy_app" to execute TF script and then copy app artifacts to GCP.
- Provide inputs in terraform.tfvars file
