process DREP_RECLUSTER {
    
    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                def result_file = file(filename);
                if ( result_file.name == "rep_recluster_genome_data_tables.tar.gz" ) {
                    return "build_catalogue/rep_recluster_genome_data_tables.tar.gz";
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
                    return "build_catalogue/recluster_rep_genomes";
                }
                return null;
            }
        },
        mode: 'copy',
        failOnError: true    
    )

    container 'quay.io/biocontainers/drep:3.2.2--pyhdfd78af_0'

    input:
    path rep_genomes

    output:
    path "rep_recluster_genome_data_tables.tar.gz", emit: drep_data_tables_tarball
    path "recluster_cdb.csv", emit: recluster_cdb_csv
    path "recluster_genomes" ,emit:recluster_rep_genomes
    

    script:
    """
    dRep compare drep_recluster \
        -g ${rep_genomes}/*.fna \
        -p ${task.cpus} \
        -sa 0.95 \
        --SkipMash \
        --S_algorithm ANImf \
        -nc 0.30 \
        -cm larger \
        --clusterAlg complete
         
    tar -czf rep_recluster_genome_data_tables.tar.gz drep_recluster/data_tables
    mv drep_recluster/data_tables/Cdb.csv recluster_cdb.csv
    mv drep_recluster/dereplicated_genomes/ recluster_genomes
    
    """
}