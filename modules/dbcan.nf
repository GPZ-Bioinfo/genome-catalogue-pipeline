process DBCAN {

    tag "${cluster_name}"
    
    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                String cluster_prefix = cluster_name;
                return "species_catalogue/${cluster_prefix}/genome/${cluster_name}_dbcan.gff"
            }
        },
        mode: 'copy',
        failOnError: true
    )

    container 'quay.io/biocontainers/dbcan:4.1.2--pyhdfd78af_0'

    input:
    tuple val(cluster_name), path(faa), path(gff)
    path(dbcan_db, stageAs: "dbcan_db")

    output:
    tuple val(cluster_name), path("dbcan/${cluster_name}_dbcan.gff")  , emit: dbcan_gff

    script:
    """
    while read line
    do
        if [[ \${line} == "##FASTA" ]]
        then
            break
        else
            echo "\$line"
        fi
    done < ${gff} > ${cluster_name}_noseq.gff

    run_dbcan \\
        --dia_cpu ${task.cpus} \\
        --hmm_cpu ${task.cpus} \\
        --tf_cpu ${task.cpus} \\
        --db_dir dbcan_db \\
        --out_dir dbcan \\
        --cgc_substrate \\
        --cluster ${cluster_name}_noseq.gff \\
        ${faa} \\
        protein

    process_dbcan_result.py -i dbcan -o dbcan/${cluster_name}_dbcan.gff -v 4.1.2

    """
}
