process FUNCTIONAL_ANNOTATION_SUMMARY {

    label 'process_light'

    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                def cluster_prefix = cluster_name;
                return "species_catalogue/${cluster_prefix}/genome/${filename}";
            }
        },
        mode: "copy",
        failOnError: true
    )

    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'

    input:
    tuple val(cluster_name), file(cluster_rep_faa), file(ips_annotation_tsvs), file(eggnog_annotation_tsvs)
    file kegg_classes

    output:
    tuple val(cluster_name), path("*_annotation_coverage.tsv"), emit: coverage
    tuple val(cluster_name), path("*_kegg_classes.tsv"), emit: kegg_classes
    tuple val(cluster_name), path("*_kegg_modules.tsv"), emit: kegg_modules
    tuple val(cluster_name), path("*_cazy_summary.tsv"), emit: cazy_summary
    tuple val(cluster_name), path("*_cog_summary.tsv"), emit: cog_summary

    script:
    """
    functional_annotations_summary.py \
    -f ${cluster_rep_faa} \
    -i ${ips_annotation_tsvs} \
    -e ${eggnog_annotation_tsvs} \
    -k ${kegg_classes}
    """

    stub:
    """
    touch ${cluster_rep_faa.baseName}_annotation_coverage.tsv
    touch ${cluster_rep_faa.baseName}_kegg_classes.tsv
    touch ${cluster_rep_faa.baseName}_kegg_modules.tsv
    touch ${cluster_rep_faa.baseName}_cazy_summary.tsv
    touch ${cluster_rep_faa.baseName}_cog_summary.tsv
    """
}
