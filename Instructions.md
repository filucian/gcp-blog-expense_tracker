#Project Instructions and Pending items

## Sources

- [ Setting Up CDN with Bucket ](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket#gcloud)
- [Set up a Backend bucket](https://cloud.google.com/cdn/docs/quickstart-backend-bucket-console)
- [Set up DNS](https://cloud.google.com/dns/docs/set-up-dns-records-domain-name)
- [Bash Output Redirection](https://www.cyberithub.com/how-to-suppress-or-hide-all-the-output-of-a-linux-bash-shell-script)

## Instructions

### Run BASH Script

- Input DOMAIN_NAME, PROJECT_ID and APP_NAME in ./deployment-script/parameters-deploy.sh
- Run ./deployment-script/deploy-cdn.sh

### Run Terraform Configuration

Run `make help` in terraform-config/ for further instructions

### Run on GCP Console

1. Create Project.
2. Assign Project to a Billing Account.
3. Create Cloud Storage Bucket to store Frontend Build Artifacts.
4. Copy Frontend Build Artifacts into Cloud Storage Bucket.
5. Set index.html as default page.
6. Make all contents on storage bucket as Public for serving on internet.
7. Create an external IP address to attach Domain Name.
8. Create External Load Balancer (Start Configuration)
   a. Choose Internet to my VMs
   b. Choose load balancer type in Advanced traffic management
   c. Create backend by selecting previously created bucket.
   d. Enable Cloud CDN.
9. Create Host rules and path matchers
10. After few minutes, check that the Load balancer created is healthy.
11. Test youur load balancer using web browser by going to http://IP_ADDRESS/
12. Configure DNS. Create Public Zone.
13. Create A Records and CNAME records to point preciso.in and www.preciso.in to this Zone.
14. Copy NS Records from DNS Zone into Godaddy Hosting DNS Manager.
15. Check if Site is running with Build deployed on Google CDN.

## Notes

1. When using Gcloud Console URL Maps, Target proxies, Forwarding Rules are automatically created. Whereas one has to create them specifically using GCloud CLI.
2. It takes a few minutes for the CDN to start serving.
   - Similarly for DNS records to update.

## Todo:

```
a. Setup Terraform
b. Create cloud build file
 - https://cloud.google.com/build/docs/configuring-builds/substitute-variable-values
c. Use script to
  - Use Terraform to create backend bucket and CDN.
  - Initiate Cloud Build.
```
