process GTDBTK_QC {

    publishDir(
        path: "${params.outdir}/",
        saveAs: {
            filename -> {
                def output_file = file(filename);
                def name = output_file.getName();
                def extension = output_file.getExtension();
                if ( name  == "gtdbtk_results.tar.gz" ) {
                    return "additional_data/${name}";
                }
                return null;
            }
        },
        mode: 'copy',
        failOnError: true
    )

    container 'quay.io/biocontainers/gtdbtk:2.4.0--pyhdfd78af_1'

    input:
    path rep_genome, stageAs: "genomes_dir/*"
    val extension
    path gtdbtk_refdata, stageAs: "database"

    output:
    path 'gtdbtk_results/classify/gtdbtk.bac120.summary.tsv', optional: true, emit: gtdbtk_summary_bac120
    path 'gtdbtk_results/classify/gtdbtk.ar53.summary.tsv', optional: true, emit: gtdbtk_summary_arc53
    path 'gtdbtk_results/align/gtdbtk.bac120.user_msa.fasta.gz', optional: true, emit: gtdbtk_user_msa_bac120
    path 'gtdbtk_results/align/gtdbtk.ar53.user_msa.fasta.gz', optional: true, emit: gtdbtk_user_msa_ar53
    path 'gtdbtk_results.tar.gz', emit: gtdbtk_output_tarball

    script:
    """

    GTDBTK_DATA_PATH=\$PWD/database \
    gtdbtk classify_wf \
    --cpus ${task.cpus} \
    --pplacer_cpus ${task.cpus} \
    --genome_dir genomes_dir \
    --extension ${extension} \
    --skip_ani_screen \
    --out_dir gtdbtk_results

    process_gtdb_unknowns.py -i gtdbtk_results -p processed
    if [ -e gtdbtk_results/classify/processed_gtdbtk.bac120.summary.tsv ]
    then
        mv gtdbtk_results/classify/processed_gtdbtk.bac120.summary.tsv gtdbtk_results/classify/gtdbtk.bac120.summary.tsv
    fi
    
    if [ -e gtdbtk_results/classify/processed_gtdbtk.ar53.summary.tsv ]
    then
        mv gtdbtk_results/classify/processed_gtdbtk.ar53.summary.tsv gtdbtk_results/classify/gtdbtk.ar53.summary.tsv
    fi
    
    tar -czf gtdbtk_results.tar.gz gtdbtk_results
    """

}
