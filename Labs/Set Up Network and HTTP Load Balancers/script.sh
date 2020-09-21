#! /bin/sh
# Initialization of Script
gcloud init --skip-diagnostics < a

echo "Script sets up the Nginx server upon startup"
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

gcloud config set compute/zone us-central1-a
gcloud config set compute/region us-central1
echo "Create an instance template, which uses the startup script"
gcloud compute instance-templates create nginx-template \
         --metadata-from-file startup-script=startup.sh
		 
echo "A target pool allows a single access point to all the instances in a group and is necessary for load balancing "
gcloud compute target-pools create nginx-pool

echo "Create a managed instance group using the instance template:"
gcloud compute instance-groups managed create nginx-group \
         --base-instance-name nginx \
         --size 2 \
         --template nginx-template \
         --target-pool nginx-pool
		 
echo "List the compute engine instances"
gcloud compute instances list

echo "configure a firewall so that you can connect to the machines on port 80 via the EXTERNAL_IP addresses"		 
gcloud compute firewall-rules create www-firewall --allow tcp:80

echo "----------------------------------"
echo "Create a Network Load Balancer"		 
gcloud compute forwarding-rules create nginx-lb \
         --region us-central1 \
         --ports=80 \
         --target-pool nginx-pool

echo "List all Compute Engine forwarding rules in your project."
gcloud compute forwarding-rules list

echo "----------------------------------"
echo "Create a HTTP(s) Load Balancer"
echo "Create health check"
gcloud compute http-health-checks create http-basic-check

echo "Define an HTTP service and map a port name to the relevant port for the instance group"
gcloud compute instance-groups managed \
       set-named-ports nginx-group \
       --named-ports http:80
	   
echo "create backend service"
gcloud compute backend-services create nginx-backend \
      --protocol HTTP --http-health-checks http-basic-check --global

echo "Add the instance group into the backend service"
gcloud compute backend-services add-backend nginx-backend \
    --instance-group nginx-group \
    --instance-group-zone us-central1-a \
    --global

echo "Create a default URL map that directs all incoming requests to all your instances"
gcloud compute url-maps create web-map \
    --default-service nginx-backend

echo "Create a target HTTP proxy to route requests to your URL map"
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map
	
echo "Create a global forwarding rule to handle and route incoming requests"
gcloud compute forwarding-rules create http-content-rule \
        --global \
        --target-http-proxy http-lb-proxy \
        --ports 80

echo "Verify or list the rules"
gcloud compute forwarding-rules list

gcloud auth revoke --all
