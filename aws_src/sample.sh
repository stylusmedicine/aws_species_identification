#!/bin/bash

set -e  # Exit on any error

# 🚀 Step 1: Ask for the input FASTQ file
read -p "Enter the name of the FASTQ file (with .fastq.gz): " FASTQ_FILE

# Check if the file exists
if [ ! -f "$FASTQ_FILE" ]; then
    echo "❌ File not found: $FASTQ_FILE"
    exit 1
fi

# 🚀 Step 2: Ask for output file name
read -p "Enter the desired output file name (without .fasta extension): " OUTPUT_NAME
OUTPUT_FILE="${OUTPUT_NAME}.fasta"

# 🚀 Step 3: Randomly sample 1000 reads and convert to FASTA
echo "Sampling 1000 reads from $FASTQ_FILE..."
zcat "$FASTQ_FILE" | seqtk sample -s100 - 1000 | seqtk seq -A > "$OUTPUT_FILE"

# 🚀 Step 4: Verify the output
if [ -f "$OUTPUT_FILE" ]; then
    echo "✅ Sampling complete! Output saved as $OUTPUT_FILE"
    grep -c "^>" "$OUTPUT_FILE"
else
    echo "❌ Sampling failed."
    exit 1
fi

