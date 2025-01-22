process DREP_DEDUPLICATE {
    
    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                def result_file = file(filename);
                if ( result_file.name == "drep_data_tables.tar.gz" ) {
                    return "quality_control/passqc_drep_data_tables.tar.gz";
                }
                return null;
            }
        },
        mode: 'copy',
        failOnError: true
    )

    container 'quay.io/biocontainers/drep:3.2.2--pyhdfd78af_0'

    input:
    path passqc_genomes_folder
    path passqc_checkm_csv
    path extra_weighted_tsv

    output:
    path "drep_data_tables.tar.gz", emit: drep_data_tables_tarball
    path "drep_dedupliacte/data_tables/Mdb.csv",emit: mash_dist_csv
    path "drep_dedupliacte/dereplicated_genomes", emit: dereplicated_genomes
    path "drep_dedupliacte/data_tables/genomeInfo.csv", emit: derep_genomeInfo

    script:
    """
    dRep dereplicate drep_dedupliacte \
        --genomeInfo ${passqc_checkm_csv} \
        -g ${passqc_genomes_folder}/*.fna \
        -p ${task.cpus} \
        --SkipSecondary \
        -pa 0.999 \
        -nc 0.30 \
        -cm larger \
        -comp 50 \
        -con 5 \
        -extraW ${extra_weighted_tsv} \
        -ms 10000 

    tar -czf drep_data_tables.tar.gz drep_dedupliacte/data_tables
    """
}