#!/bin/bash
# Deploys react app created in vite to Google CDN.

# Usage
# Update parameters-deploy.sh with
# - Domain Name
# - Project Id
# - App Name
# Pass --help to get Usage instructions on the CLI

#{{{ Bash settings
# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't hide errors within pipes
set -o pipefail
#  "Setting debugging mode"
set +x
#}}}

cd deployment-script

source utils.sh
printinfo "Running Script\n"

initializeEnvt

check_Frontend "$frontend_name"

cd "../$frontend_name"
yarn

rm -rf dist
yarn build
printsuccess "\nRebuilt React App build folder\n"

gcloud config set project "$PROJECT_ID" &>/dev/null

if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
  printsuccess "GCP Project $PROJECT_ID Found"
else
  printinfo "Creating Google Cloud project $PROJECT_ID"
  gcloud projects create "$PROJECT_ID" || {
    printerror "Error while creating $PROJECT_ID. \nPlease provide new unique Project ID"
    exit
  }

  printsuccess "Successfully created $PROJECT_ID"
fi

enable_APIs

PROJECT_NAME=$(gcloud projects describe "$PROJECT_ID" --format json | jq -r '.name')

if gcloud storage ls "gs://$bucket_name" &>/dev/null; then
  printinfo "\nBucket $bucket_name exists"
else
  printerror "Bucket $bucket_name does not exist"

  gcloud storage buckets create \
    --project "$PROJECT_ID" \
    -c standard \
    -l $REGION \
    -b "gs://$bucket_name" || {
    printerror "Cannot create $bucket_name. \nPlease provide unique bucket name"
    exit
  }

  printsuccess "\nCreated Bucket $bucket_name"
fi

gcloud storage rm -r \
  "gs://${bucket_name}/*" \
  2>/dev/null
printsuccess "\nEmptied Bucket $bucket_name"

cd dist
gcloud storage cp -R . "gs://$bucket_name" 2>/dev/null
printsuccess "Copied new Build artifacts into bucket\n"

gsutil web set -m index.html "gs://$bucket_name" >/dev/null
printsuccess "\nindex.html set as default page"

# Make all storage objects in the bucket public across the internet.
gcloud storage buckets add-iam-policy-binding \
  "gs://${bucket_name}" \
  --member=allUsers \
  --role=roles/storage.objectViewer \
  1>/dev/null
printsuccess "\nBuild Artifacts in Cloud Storage Bucket are publicly accessible"

if gcloud compute addresses describe "$app_ip_name" --global >/dev/null; then
  printinfo "\nAddress $app_ip_name exists"
else
  printinfo "Creating Address $app_ip_name"

  gcloud compute addresses create $app_ip_name \
    --network-tier=PREMIUM \
    --ip-version=IPV4 \
    --global
# 2>/dev/null
fi

EXTERNAL_IP_ADDR=$(gcloud compute addresses describe $app_ip_name \
  --format="get(address)" \
  --global)

printsuccess "\nExternal IP Address: $EXTERNAL_IP_ADDR\n"

if gcloud compute backend-buckets describe $backend_bucket_name &>/dev/null; then
  printinfo "Compute bucket $backend_bucket_name exists"
else
  printinfo "Creating new backend bucket"

  gcloud compute backend-buckets create "$backend_bucket_name" \
    --gcs-bucket-name="$bucket_name" \
    --enable-cdn \
    --cache-mode=CACHE_ALL_STATIC

  printsuccess "Successfully created bucket: $backend_bucket_name"
fi

if gcloud compute url-maps describe "$loadbalancer_name" &>/dev/null; then
  printinfo "URL Map $loadbalancer_name exists"

else
  printinfo "Creating $loadbalancer_name"
  gcloud compute url-maps create "$loadbalancer_name" \
    --default-backend-bucket="$backend_bucket_name"
fi

if gcloud compute target-http-proxies describe "$proxy_name" --global &>/dev/null; then
  printinfo "Proxy $proxy_name exists"
else
  printinfo "Creating proxy $proxy_name"
  gcloud compute target-http-proxies create "$proxy_name" \
    --url-map="$loadbalancer_name"
fi

if
  gcloud compute forwarding-rules describe "$forwarding_rule_name" --global &>/dev/null
then
  printinfo "Forwarding rule $forwarding_rule_name exists"
else
  printinfo "Creating forwarding-rule $forwarding_rule_name"
  gcloud compute forwarding-rules create "$forwarding_rule_name" \
    --load-balancing-scheme=EXTERNAL \
    --network-tier=PREMIUM \
    --address="$app_ip_name" \
    --global \
    --target-http-proxy="$proxy_name" \
    --ports=80
fi

if
  gcloud dns managed-zones describe "$managed_zone" &>/dev/null
then
  printinfo "DNS Zone $managed_zone exists"
else
  printinfo "Creating DNS Zone $managed_zone"
  gcloud dns managed-zones create "$managed_zone" \
    --description="Zone for vite app" \
    --dns-name="$DOMAIN_NAME" \
    --visibility=public
fi

nameservers=$(gcloud dns record-sets list --zone "$managed_zone" --format json | jq '.[] | select(.type=="NS") | .rrdatas')

printsuccess "\nPlease add the following Nameservers to your Domain:"
printinfo "${nameservers}\n"

if gcloud dns \
  --project="$PROJECT_ID" \
  record-sets describe "$DOMAIN_NAME." \
  --type=A \
  --zone="$managed_zone" &>/dev/null; then

  printinfo "A Records exist for $DOMAIN_NAME"
else
  printinfo "Creating A Records in the DNS"
  gcloud dns \
    --project="$PROJECT_ID" \
    record-sets create "$DOMAIN_NAME." \
    --type="A" \
    --zone="$managed_zone" \
    --rrdatas="$EXTERNAL_IP_ADDR" \
    --ttl="300"
fi

if gcloud dns \
  --project="$PROJECT_ID" \
  record-sets describe "www.${DOMAIN_NAME}." \
  --type=CNAME \
  --zone="$managed_zone" &>/dev/null; then

  printinfo "CNAME records exist\n"
else
  gcloud dns --project="$PROJECT_ID" record-sets create \
    "www.${DOMAIN_NAME}." \
    --type="CNAME" \
    --zone="$managed_zone" \
    --rrdatas="${DOMAIN_NAME}." \
    --ttl="300"
fi

response=$(curl -l -s -o /dev/null -w "%{http_code}" "$EXTERNAL_IP_ADDR")

if [ "$response" -eq 200 ]; then
  printsuccess "The website is up on $EXTERNAL_IP_ADDR"
else
  printerror "The server is not yet running. Please try after 5 mins"
fi

website_url="http://www.${DOMAIN_NAME}"

response=$(curl -l -s -o /dev/null -w "%{http_code}" "$website_url")

if [ "$response" -eq 200 ]; then
  printsuccess "The website is up on $website_url"
else
  printerror "The website is not yet running. Please try after 5 mins"
fi

printinfo "\nDone Running Script"

printinfo "\nDelete project $PROJECT_NAME to delete all created resources and prevent GCP charges."

exit
