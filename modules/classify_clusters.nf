/*
This script does detection and separation of genomes into clusters according drep results.
Script generates clusters_split.txt file with information about each cluster:
    ex:
        many_genomes:1_1:CAJJTO01.fa,CAJKGB01.fa,CAJLGA01.fa
        many_genomes:2_1:CAJKRE01.fa,CAJKXJ01.fa
        one_genome:3_0:CAJKRY01.fa
        one_genome:4_0:CAJKXZ01.fa

If you want to return cluster folders with mash-files - use --create-clusters flag and set -f path
    ex. of output:
        split_outfolder
        - 1_1
            ---- CAJJTO01.fa
            ---- CAJKGB01.fa
            ---- CAJLGA01.fa
            ---- 1_1_mash.tsv
        - 2_1
            ---- CAJKRE01.fa
            ---- CAJKXJ01.fa
            ---- 2_1_mash.tsv
        - 3_0
            ---- CAJKRY01.fa
            ---- 3_0_mash.tsv
        - 4_0
            ---- CAJKRY01.fa
            ---- 4_0_mash.tsv
*/

//*extention use .fna.gz instead 
process CLASSIFY_CLUSTERS {

    label "process_light"

    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'

    input:
    path dereplicated_genomes
    file split_text_file

    output:
    path "pg/**/*.fna", emit: many_genomes_fnas
    path "sg/**/*.fna", emit: one_genome_fnas
    path "allg/**/*.fna", emit: all_genome_fnas

    script:
    """
    classify_folders.py -g ${dereplicated_genomes} --text-file ${split_text_file}

    #Clean any empty directories #
    find many_genomes -type d -empty -print -delete
    find one_genome -type d -empty -print -delete
    find all_genomes -type d -empty -print -delete

    mv many_genomes pg
    mv one_genome sg
    mv all_genomes allg
    """
}
