process CHECKM2 {

    publishDir(
        path: "${params.outdir}",
        pattern: "checkm_result_file.csv",
        saveAs: { "additional_data/intermediate_files/checkm_quality_genomes.csv" },
        mode: "copy",
        failOnError: true
    )
    publishDir(
        path: "${params.outdir}",
        pattern: "${ch_prefix}_add_checkm_metadata.csv",
        saveAs: { "additional_data/intermediate_files/add_checkm_metadata.csv" },
        mode: "copy",
        failOnError: true
    )

    container 'quay.io/biocontainers/checkm2:1.0.1--pyh7cba7a3_0'

    input:

    path renamed_genomes_folder
    path renamed_genome_metadata_csv
    path ch_checkm2_db
    val ch_prefix

    output:
    path "checkm_result_file.csv", emit: checkm_csv
    path "${ch_prefix}_add_checkm_metadata.csv", emit: genomes_add_checkm_metadata_csv

    //*add checkmresults combine with other metadata
    script:
    """
    checkm2 predict \
    --threads ${task.cpus} \
    --input ${renamed_genomes_folder} \
    -x fna \
    --output-directory checkm_output \
    --database_path ${ch_checkm2_db}

    # add in extensions #
    add_extensions_to_checkm.py -i checkm_output -d ${renamed_genomes_folder}
    # to csv #
    checkm2csv.py -i checkm_output/quality_report.tsv --checkm2 > checkm_result_file.csv
    checkm2addmetadata.py -cm checkm_result_file.csv -i ${renamed_genome_metadata_csv} -o ${ch_prefix}_add_checkm_metadata.csv
    """
}
