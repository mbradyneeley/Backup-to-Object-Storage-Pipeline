configfile: "./config.yaml"


rule all:
    input:
        "rclone_archive_crams.ok"


# Archives all files that are descendents of "rootDirForArchive" except .bam/.bai
# TODO: I think the following rule still archives some bams. Not sure if excludes
# extension .bam or if it checks the actual code and soft links don't get excluded...
rule archive_files:
    input:
        root=config["rootDirForArchive"]
    message:
        "Archiving all files from {input.root} except for .bam/.bai"
    log:
        "logs/archiveFiles.log"
    output:
        touch("rsync_archive.ok")
    shell:
        """
        ml rclone
        for file in {input.root}/*
        do
            fileBase=$(basename $file)
            fileName=${{fileBase%.*}}
            tar --exclude='*.bam*' -zcvf - $file | rclone rcat pezz:{input.root}/${{fileName}}.tar.gz
        done
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
    log:
        "logs/findBams.log"
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
        bams="bamsFound.txt",
        tempDir=config["tempDir"],
        ref=config["reference"]
    output:
        touch("conversion_complete.ok")
    message:
        "Converting bams to crams..."
    log:
        "logs/cramConversion.log"
    shell:
        """
        DIR={input.tempDir}
        echo $DIR
        if [ ! -d "$DIR" ]; then
            mkdir $DIR
        fi
        while read line; do
            bam=$(basename $line)
            bamName=${{bam%.*}}
            echo $line to ${{DIR}}/${{bamName}}.cram
            samtools view \
            -T {input.ref} \
            -C \
            -o ${{DIR}}/${{bamName}}.cram \
            $line
        done < {input.bams}
        """

# Send crams to storage then remove crams
rule send_cram_to_storage:
    input: 
        conversionComplete="conversion_complete.ok",
        tempDir=config["tempDir"]
    output:
        touch("rclone_archive_crams.ok")
    message:
        "Sending crams to storage"
    log:
        "logs/cramToStorage.log"
    shell:
        """
        ml rclone
        OUTPUTDIR={input.tempDir}
        rclone copy $OUTPUTDIR pezz:testCram -v
        ls -1 $OUTPUTDIR >> logs/cramToStorage.log
        rm -r $OUTPUTDIR
        """
