sudo mkdir -p /mnt/ebs
sudo mkfs -t xfs /dev/nvme1n1
sudo mount /dev/nvme1n1 /mnt/ebs
sudo chown -R ec2-user:ec2-user /mnt/ebs
echo "/dev/nvme1n1 /mnt/ebs xfs defaults,nofail 0 2" | sudo tee -a /etc/fstab
df -h /mnt/ebs

