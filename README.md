# BLAST Species ID in AWS 

This repository contains scripts to launch and configure an AWS EC2 instance for species ID. The repository is organized into three main directories:

- **local_src/**: Contains scripts that you run on your local machine.
- **aws_src/**: Contains scripts to be executed on the EC2 instance after you log in.
- **downstream_src/**: Contains an R script for "ranked choice voting" scoring to determine likely species.

## Repository Structure

```
README.md
aws_src/
  ├── mount.sh
  ├── run_blast.sh
  ├── sample.sh
  └── set_up_instance.sh
downstream_src/
  └── species_id.R
local_src/
  └── launch_instance.sh
```

## Overview

- **Local Setup (`local_src/launch_instance.sh`):**  
  Run this script on your local machine to launch an AWS EC2 instance. The script uses the AWS CLI to start the instance, waits for it to be running, and outputs the instance's public IP address along with the SSH command needed to log in.

- **AWS Instance Setup (`aws_src/`):**  
  Once you log in to your EC2 instance via SSH, use the scripts in the `aws_src` directory to configure your environment:
  - `set_up_instance.sh`: Configures the AWS CLI, installs Miniconda, creates a Conda environment, and installs essential bioinformatics tools (e.g., `seqtk` and `blast+`).
  - `mount.sh`: Formats and mounts an attached EBS volume to `/mnt/ebs` for data storage.
  - `sample.sh`: Samples 1000 reads from a specified FASTQ file and converts them to FASTA format.
  - `run_blast.sh`: Runs a BLAST search on the sampled data, uploads the results to S3, and terminates the EC2 instance upon successful completion.

- **Downstream Analysis (`downstream_src/`):**  
  - `species_id.R`: R script for species determination

## How to Use

1. **Launch EC2 Instance Locally:**
   - Navigate to the `local_src` directory.
   - Run the `launch_instance.sh` script to start your EC2 instance:
     ```bash
     cd local_src
     chmod +x launch_instance.sh
     ./launch_instance.sh
     ```
   - The script will output the instance's public IP and provide the SSH command to connect. It will launch an r5.16xlarge instance with 500gb storage.

2. **Configure the EC2 Instance:**
   - SSH into the EC2 instance using the provided command.
   - Once logged in, navigate to the `aws_src` directory on the instance (download this repo on the ec2 instance).
   - Execute the scripts in the following order as needed:
     1. **`set_up_instance.sh`** – Sets up the environment by installing Miniconda, creating a Conda environment, and installing essential tools.
     2. **`mount.sh`** – Formats and mounts the EBS volume. The mount will be at `/mnt/ebs`. This is where all analysis should take place from here on out. 
     
     Between these two steps, download the blastdb from S3 to the EC2 instance. Make sure it's downloaded to the mounted volume (`/mnt/ebs`). This can be done using the following command: <br>
     ```
     aws s3 cp --recursive s3://latchbio-stylus/vertebrate_mammalians_blasttdb/ vertebrate_mammalians_blasttdb/
     ```
     <br> At this point, the raw FASTQ data also needs to be downloaded to the instance. Use `aws s3 cp` to download this as well. <br>
     3. **`sample.sh`** – Samples FASTQ data (1000 reads) and converts it to FASTA format. 
     4. **`run_blast.sh`** – Runs BLAST, uploads results to S3, and automatically terminates the instance.

3. **Downstream Analysis:**
   - There is an Rscript here to run the "ranked choice voting" scoring algorithms to determine species ID. Since the EC2 instance terminates once blast results have been uploaded, this should be run locally (or on a latch pod).

## Prerequisites

- **AWS CLI:** Ensure that it is installed and properly configured with the necessary credentials and permissions.

## Final Notes

- **Automation and Cost Efficiency:**  
  The `run_blast.sh` script automatically terminates the EC2 instance after a successful run to help manage AWS costs.

- **Customization:**  
  You can modify the script parameters (e.g., instance types, file paths, BLAST settings) as needed.

