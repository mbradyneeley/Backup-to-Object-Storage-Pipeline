# Backup to Object Storage Snakemake Pipeline

## Overview
The end all of this workflow is to move archived/compressed files to object storage. This was built with ceph in mind, whose API is compatible with the basic data access model of the Amazon S3 API. This can easily be tweaked for like storage systems. Our labs data consists of alot of NGS data. We decided to hold onto our raw reads in fasta format but want to convert our bams to crams to save space in our archive. Bams are converted to crams on the fly and are held in a temp directory while they are transferred to the object storage. The original bams are not also archived, only the newly made crams. Note, this workflow only currently works with one reference file which you provide in the config.


Provide the absolute path to a directory which I call the rootDir. The workflow proceeds with the following processes using the rootdir:

1. Archive and compress everything within the rootDir except for bam files and send to the object storage with Rclone.
2. Find the bams that were skipped in the first step.
3. Convert all bams to crams.
4. Send crams to object storage.

## Requirements

* Have an Rclone config set up and ready to go
  * Here is a helpful link for setting it up with a number of storage services: https://www.chpc.utah.edu/documentation/software/rclone.php 
* Pipeline Dependencies:
  * Rclone
  * samtools
  * GNU tar

## Running the Workflow

Open up the config.yaml file and edit the following parameters (using absolute paths when paths are needed):
 * `rootDirForArchive` - Everything inside of this directory (sub files and dirs) will be processed and sent to storage
 * `tempDir` - This directory will hold your crams as they are being made and are sent to storage. This should be in a scratch space or the like.
 * `reference` - The reference file you used for mapping your reads. Note: This reference must be available at all times. Losing it may be equivalent to losing all your read sequences. This is required to 'decode' your cram files as they use reference based compression.
 * `Parameters for your system's workload manager`
