process SPLIT_DREP {

    publishDir(
        path: "${params.outdir}",
        saveAs: {
            filename -> {
                def output_file = file(filename);
                if ( output_file.name == "clusters_split.tsv" ) {
                    return "additional_data/intermediate_files/clusters_split.tsv";
                }
                return null;
            }
        },
        mode: "copy",
        failOnError: true
    )

    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'

    input:
    file cdb_csv
    file mdb_csv // optional, use file("NO_FILE") when empty
    file sdb_csv

    output:
    path "split_output/clusters_split.tsv", emit: text_split
    path "split_output/mash_folder/*.tsv", optional: true, emit: mash_splits

    script:
    def mdb_arg = mdb_csv.name != "NO_FILE" ? "--mdb ${mdb_csv}" : ""
    """
    split_drep.py \
    --cdb ${cdb_csv} \
    --sdb ${sdb_csv} \
    -o split_output ${mdb_arg}
    """

}