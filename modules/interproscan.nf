/*
 * Interproscan
*/

process IPS {

    container 'quay.io/microbiome-informatics/genomes-pipeline.ips:5.62-94.0'
    containerOptions "-v ${params.interproscan_db}:/opt/interproscan-5.62-94.0/data"

    label 'ips'

    input:
    file faa_fasta
    path interproscan_db

    output:
    path '*.IPS.tsv', emit: ips_annotations

    script:
    """
    interproscan.sh \
    -cpu ${task.cpus} \
    -dp \
    --goterms \
    -pa \
    -f TSV \
    --input ${faa_fasta} \
    -o ${faa_fasta.baseName}.IPS.tsv
    """
}
