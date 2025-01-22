process PREPARE_SGB_INFO {

    publishDir(
        path: "${params.outdir}",
        pattern: "catalogue_genomeinfo.csv",
        saveAs: { "quality_control/${ch_prefix}_catalogue_genomeinfo.csv" },
        mode: "copy",
        failOnError: true
    )

    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'

    input:
    path dereplicated_genomes
    path derep_genomeInfo
    path extra_weighted_tsv
    val ch_prefix

    output:
    path "catalogue_genomeinfo.csv", emit: catalog_genomeinfo_csv
    path "catalogue_extra_weights.tsv", emit: catalog_extra_weighted_tsv
    

    script:
        """
        prepare_sgb_info.py \
        -g ${dereplicated_genomes} \
        -i ${derep_genomeInfo} \
        -e ${extra_weighted_tsv} \
        -og catalogue_genomeinfo.csv \
        -oe catalogue_extra_weights.tsv
        """
}