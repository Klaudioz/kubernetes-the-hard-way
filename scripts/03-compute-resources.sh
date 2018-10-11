echo "03.- Provisioning Compute Resources"
echo "Assuming: gcloud SDK, cfssl and kubectl installed, Default Compute Region and Zone ready"
echo "Creating the custom VPC network"
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
echo "Creating the subnet in the VPC network"
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24
echo "Creating a rule that allows internal communication across all protocols"
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16
echo "Creating a firewall rule that allows external SSH, ICMP, and HTTPS"
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0
echo "Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers"
gcloud compute addresses create kubernetes-the-hard-way --region $(gcloud config get-value compute/region)
echo "Showing static IP address was in your default compute region"
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"
echo "Creating three compute instances which will host the Kubernetes control panel"
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
echo "Creating three compute instances which will host the Kubernetes worker nodes"
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
echo "Listing the compute instances in your default compute zone"
gcloud compute instances list
echo "END"