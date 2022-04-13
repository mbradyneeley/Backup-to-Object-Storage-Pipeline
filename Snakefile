configfile: "./config.yaml"

rule all:
    input:
        "bamLocations.txt"

# Archives all files that are descendents of "rootDirForArchive" except .bam/.bai
# TODO:Have a for loop with list of directories to be archived or maybe make a
# list of directories in config that are iteratively archived.
rule archive_files:
    input:
        root=config["rootDirForArchive"]
    message:
        "Archiving all files from {input.root} except for .bam/.bai"
    output:
        touch("rsync_archive.ok")
    shell:
        """
        ml rclone
        tar --exclude='*.bam*' -zcvf - {input} | rclone rcat pezz:{input}/testArchive.tar.gz
        """

# Now we find the bams that were excluded in the archive_files step:
#   1. First find every bam file
#   2. Remove file name and just keep path to file
#   3. Sort and unique the paths
#   4. Remove temporary files
rule find_bams:
    input:
        "rsync_archive.ok",
        root=config["rootDirForArchive"]
    message:
        "Searching for bams to archive..."
    output:
        "bamLocations.txt" 
    shell:
        """
		touch bamLocations.txt
        find {input.root} -name "*bam" > bamsFound.txt

		while IFS= read -r line
		do
			dir=$(dirname $line)
			echo $dir >> {output}.temp
		done < bamsFound.txt

        sort {output}.temp | uniq > {output}

        rm {output}.temp bamsFound.txt 
        """

# TODO: Store crams in a certain way that they are easily tied to the archived folder
# the bams were excluded from.
# TODO: Have this log really well. Make a crams folder. Print to log which folder each full path cram
# is sent to.
rule bam_to_cram:
    input:
        bams="bamLocations.txt"
    output:
        temp("/scratch/general/lustre/u0854535/crams/{sample}.dedup.realigned.realigned.bqsr.cram")
    message:
        "Converting bams to crams..."
    shell:
        """
        DIR=/scratch/general/lustre/u0854535/crams
        if [ ! -d "$DIR" ]; then
            mkdir $DIR
        fi
        samtools view \
        -T /uufs/chpc.utah.edu/common/home/pezzolesi-group1/resources/GATK/b37/human_g1k_v37_decoy_phix.fasta \
        -C \
        -o {output} \
        /scratch/general/lustre/u0854535/temp/bams/{wildcards.sample}.dedup.realigned.realigned.bqsr.bam
        """

