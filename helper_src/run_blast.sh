#!/bin/bash

# Set paths
DB_PATH="/mnt/ebs/vertebrate_mammalians_blasttdb/vertebrate_mammalians_db"
QUERY="/mnt/ebs/24TGPJ/fastq_sample_1000_reads.fasta"
OUTPUT="/mnt/ebs/24TGPJ/blast_fastq_sample_1000_reads.txt"

# Preload database into memory (optional)
blastdbcmd -db "$DB_PATH" -info > /dev/null

# Run BLAST with optimized settings for 32 cores
blastn -db "$DB_PATH" \
      -query "$QUERY" \
      -out "$OUTPUT" \
      -task megablast \
      -word_size 28 \
      -evalue 1e-5 \
      -max_target_seqs 10 \
      -max_hsps 1 \
      -perc_identity 90 \
      -lcase_masking \
      -soft_masking true \
      -num_threads 64 \
      -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore sskingdoms ssciname"

# Upload results to S3
aws s3 cp "$OUTPUT" s3://latchbio-stylus/Plasmidsaurus/species_identification/results/24TGPJ/

# Confirm upload success
if [ $? -eq 0 ]; then
    echo "BLAST results successfully uploaded to S3."
else
    echo "Upload to S3 failed. Instance will NOT terminate."
    exit 1
fi

# Automatically terminate the EC2 instance
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

echo "EC2 instance is terminating..."
