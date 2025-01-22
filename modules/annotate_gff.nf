process ANNOTATE_GFF {

    tag "${cluster_name}"

    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                String cluster_prefix = cluster_name;
                return "species_catalogue/${cluster_prefix}/genome/${gff.simpleName}_annotated.gff";
            }
        },
        mode: 'copy',
        failOnError: true
    )
    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                String cluster_prefix =cluster_name;
                return "all_genomes/${cluster_prefix}/${gff.simpleName}.gff";
            }
        },
        mode: 'copy',
        failOnError: true
    )

    label 'process_light'

    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'

    input:
    tuple val(cluster_name),
        file(gff),
        file(eggnog_annotations_tsv),
        file(dbcan_gff),
        file(ips_annotations_tsv)
    
    output:
    tuple val(cluster_name), path("*_annotated.gff"), emit: annotated_gff

    script:

    if ( dbcan_gff ) {
        dbcan_flag = "--dbcan ${dbcan_gff}"
    }
    """
    
    annotate_gff.py \
    -g ${gff} \
    -i ${ips_annotations_tsv} \
    -e ${eggnog_annotations_tsv} \
    -o ${cluster_name}_annotated.gff \
    ${dbcan_flag}
    """

    stub:
    """
    touch ${gff.simpleName}_annotated.gff
    """
}
