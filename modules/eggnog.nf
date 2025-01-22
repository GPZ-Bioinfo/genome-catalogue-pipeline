/*
 * eggNOG-mapper
*/

process EGGNOG_MAPPER {

    container 'quay.io/microbiome-informatics/genomes-pipeline.eggnog-mapper:v2.1.11'

    input:
    // on mode "annotations" will be ignored, submit an empty path (channel.path("NO_FILE"))
    file fasta
    // on mode "mapper" will be ignored, submit an empty path (channel.path("NO_FILE"))
    file annotation_hit_table
    val mode // mapper or annotations
    path eggnog_db
    path eggnog_diamond_db
    path eggnog_data_dir

    output:
    path "*annotations*", emit: annotations, optional: true
    path "*orthologs*", emit: orthologs, optional: true

    script:
    if ( mode == "mapper" )
        """
        emapper.py -i ${fasta} \
        --database ${eggnog_db} \
        --dmnd_db ${eggnog_diamond_db} \
        --data_dir ${eggnog_data_dir} \
        -m diamond \
        --no_file_comments \
        --cpu ${task.cpus} \
        --no_annot \
        --dbmem \
        -o ${fasta.baseName}
        """
    else if ( mode == "annotations" )
        """
        emapper.py \
        --data_dir ${eggnog_data_dir} \
        --no_file_comments \
        --cpu ${task.cpus} \
        --annotate_hits_table ${annotation_hit_table} \
        --dbmem \
        --tax_scope 'prokaryota_broad' \
        -o ${annotation_hit_table.baseName}
        """
    else
        error "Invalid mode: ${mode}"

}
