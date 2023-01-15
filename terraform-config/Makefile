help:
	@echo "deploy_app        => Apply TF configuration And Copy build files for react app to Google Cloud bucket"
	@echo "initialize_bucket => Copy build files for react app to Google Cloud bucket"
	@echo "create_deployment => Apply TF configuration"
	@echo "Above command needs the bucket to be created beforehand"

	@echo "\n\ndelete_deployment => Destroy infrastructure created by this configuration"
	
BUCKET_NAME := $(shell terraform output bucket)

initialize_bucket:
	@echo "Run this command only after creating GCP resources with Terraform"
	sleep 5
	- gcloud storage rm -r "gs://${BUCKET_NAME}/*" 
	cd ../vite-frontend && rm -rf dist
	cd ../vite-frontend && yarn build
	cd ../vite-frontend/dist && gcloud storage cp -R . "gs://$(BUCKET_NAME)"

create_deployment:
	terraform apply -auto-approve

deploy_app: create_deployment initialize_bucket

delete_deployment:
	terraform destroy -auto-approve