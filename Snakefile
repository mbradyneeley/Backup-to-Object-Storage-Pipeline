configfile: "./config.yaml"

rule all:
    input:
        "rclone_archive_crams.ok"

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
        "bamsFound.txt" 
    shell:
        """
        find {input.root} -name "*bam" > bamsFound.txt
        """

# TODO: Store crams in a certain way that they are easily tied to the archived folder
# the bams were excluded from.
# TODO: Have this log really well. Make a crams folder. Print to log which folder each full path cram
# is sent to.
# TODO: Add DIR to config so user can set temp dir of choice.
rule bam_to_cram:
    input:
        bams="bamsFound.txt"
    output:
        touch("conversion_complete.ok")
    message:
        "Converting bams to crams..."
    log:
        "logs/cramConversion.log"
    shell:
        """
        DIR=/scratch/general/lustre/u0854535/crams
        echo $DIR
        if [ ! -d "$DIR" ]; then
            mkdir $DIR
        fi
        while read line; do
            bam=$(basename $line)
            bamName=${{bam%.*}}
            echo $line to ${{DIR}}/${{bamName}}.cram
            samtools view \
            -T /uufs/chpc.utah.edu/common/home/pezzolesi-group1/resources/GATK/b37/human_g1k_v37_decoy_phix.fasta \
            -C \
            -o ${{DIR}}/${{bamName}}.cram \
            $line
        done < {input.bams}
        """

rule send_cram_to_storage:
    input: 
        "conversion_complete.ok"
    output:
        touch("rclone_archive_crams.ok")
    message:
        "Sending crams to storage"
    shell:
        """
        rclone copy /scratch/general/lustre/u0854535/crams/ pezz:testCram -v
        """
