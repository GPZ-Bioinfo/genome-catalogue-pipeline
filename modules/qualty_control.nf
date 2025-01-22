process QUALITY_CONTROL {

    publishDir(
        path: "${params.outdir}",
        pattern: "passqc_metadata.csv",
        saveAs: { "quality_control/${ch_prefix}_genomes_metadata_withqc.tsv" },
        mode: "copy",
        failOnError: true
    )

    publishDir(
        path: "${params.outdir}",
        pattern: "${ch_prefix}_extra_weighted_Genome.tsv",
        saveAs: { "additional_data/intermediate_files/${ch_prefix}_passqc_extra_weighted_Genome.tsv" },
        mode: "copy",
        failOnError: true
    )

    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'
    
    input:
    path new_metadata
    path renamed_genomes_folder
    val ch_quality_level
    val ch_prefix

    output:
    path "passqc_genomes_folder", emit: passqc_genomes_folder
    path "passqc_metadata.csv", emit: passqc_metadata_csv
    path "passqc_checkm.csv", emit: passqc_checkm_csv
    path "${ch_prefix}_extra_weighted_Genome.tsv", emit: extra_weighted_tsv

    script:
    """
    filtered_qc.py -m ${new_metadata} \
    -id ${renamed_genomes_folder} \
    -q ${ch_quality_level} \
    --output_folder passqc_genomes_folder \
    --output_metadata_file passqc_metadata.csv \
    --output_checkm_file passqc_checkm.csv \
    --output_extra_weight_file ${ch_prefix}_extra_weighted_Genome.tsv

    """
}