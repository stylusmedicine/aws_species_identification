#!/bin/bash

set -e  # Stop script if any command fails

# 🚀 Step 1: Configure AWS CLI (Only if needed)
echo "Configuring AWS CLI..."
aws configure
aws configure set default.region us-east-2
aws configure set default.output json

# 🚀 Step 2: Install Miniconda
echo "Downloading and installing Miniconda..."
cd /home/ec2-user
curl -o Miniconda3.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3.sh -b -p $HOME/miniconda

# 🚀 Step 3: Add Conda to PATH
echo "Configuring Conda..."
echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 🚀 Step 4: Initialize Conda (Fix for script stopping)
echo "Initializing Conda..."
conda init
eval "$(conda shell.bash hook)"  # Fix: Apply Conda changes without restarting shell

# 🚀 Step 5: Create & Activate Conda Environment
echo "Creating Conda environment..."
conda create -n bioinfo -y
conda activate bioinfo

# 🚀 Step 6: Install `seqtk` and `blast+`
echo "Installing seqtk and blast+..."
conda install -c bioconda seqtk blast -y

# 🚀 Step 7: Install `htop` and `tmux`
echo "Installing htop and tmux..."
sudo yum install -y htop tmux

echo "✅ Setup complete! Conda environment 'bioinfo' is ready with seqtk and blast+ installed."

