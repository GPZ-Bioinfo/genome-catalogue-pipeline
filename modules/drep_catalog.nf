process DREP_CATALOG {
    
    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                def result_file = file(filename);
                if ( result_file.name == "catalogue_genome_data_tables.tar.gz" ) {
                    return "build_catalogue/catalogue_genome_data_tables.tar.gz";
                }
                return null;
            }
        },
        mode: 'copy',
        failOnError: true
       
    )

    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                def result_file = file(filename);
                if ( result_file.name == "cluster_genomes" ) {
                    return "build_catalogue/rep_genomes";
                }
                return null;
            }
        },
        mode: 'copy',
        failOnError: true    
    )

    container 'quay.io/biocontainers/drep:3.2.2--pyhdfd78af_0'

    input:
    path dereplicated_genomes
    path catalog_genomeinfo_csv
    path catalog_extra_weighted_tsv
    val drepcluster_method

    output:
    path "catalogue_genome_data_tables.tar.gz", emit: drep_data_tables_tarball
    path "cluster_genomes", emit: rep_genomes
    path "drep_catalog/data/MASH_files/MASH_files/sketches/",emit: mash_chunk_files
    path "drep_catalog/data_tables/Cdb.csv", emit: catalog_cdb_csv
    path "drep_catalog/data_tables/Mdb.csv", emit: mdb_csv
    path "drep_catalog/data_tables/Sdb.csv", emit: sdb_csv
    path "drep_catalog/data_tables/Wdb.csv", emit: wdb_csv //add for update-catalog input rep genomes score

    //change mash sketch size
    //not add mgnify use chunk module for >100k genome
    script:
    """
    dRep dereplicate drep_catalog \
        --genomeInfo ${catalog_genomeinfo_csv} \
        -g ${dereplicated_genomes}/*.fna \
        -p ${task.cpus} \
        -pa 0.9 \
        -sa 0.95 \
        --S_algorithm ${drepcluster_method} \
        -nc 0.30 \
        -cm larger \
        -comp 50 \
        -con 5 \
        -extraW ${catalog_extra_weighted_tsv} \
        -ms 10000
         
    tar -czf catalogue_genome_data_tables.tar.gz drep_catalog/data_tables
    mv drep_catalog/dereplicated_genomes/ cluster_genomes
    """
}