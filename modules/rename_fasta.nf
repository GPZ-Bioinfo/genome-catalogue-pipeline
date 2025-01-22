process RENAME_FASTA {

    publishDir(
        path: "${params.outdir}",
        pattern: "*.csv",
        saveAs: { "additional_data/intermediate_files/renamed_genomes_metadata.csv" },
        mode: "copy",
        failOnError: true
    )

    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'

    input:
    path input_genomes
    path genome_metadata_tsv
    val start_number
    val max_number
    val prefix

    output:
    path "renamed_genomes_folder", emit: renamed_genomes_folder
    path "name_mapping.tsv", emit: renamed_genomes_mapping_tsv
    path "rename_genome_metadata.csv", emit: renamed_genome_metadata_csv

    script:
    """
    rename_fasta.py -d ${input_genomes} \
    -p ${prefix} \
    -i ${start_number} \
    --max ${max_number} \
    -t name_mapping.tsv \
    -o renamed_genomes_folder \
    --metadata ${genome_metadata_tsv} \
    --output_csv rename_genome_metadata.csv
    """
}