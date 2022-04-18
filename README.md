# Backup to Object Storage Snakemake Pipeline

## Overview
Provide the absolute path to a directory which I call the rootDir. The pipeline proceeds with the following processes using the rootdir:

1. (*Add that this is done for each directory in the rootDir) Archive and compress everything within the rootDir except for bam files and send to the object storage with Rclone.
2. Find the bams that were skipped in the first step.
3. Convert all bams to crams (Compresses down to about 60%).
4. (*Add this functionality from previous tests) Send crams to object storage.

## Requirements

* Have an Rclone config set up and ready to go
  * Here is a helpful link for setting it up with a number of storage services: https://www.chpc.utah.edu/documentation/software/rclone.php 
* Pipeline Dependencies:
  * Rclone
  * samtools
  * GNU tar

## TODO:
• Fit repo to Snakemake requirements so this can be linked to their repository of pipelines: https://snakemake.readthedocs.io/en/stable/snakefiles/best_practices.html
