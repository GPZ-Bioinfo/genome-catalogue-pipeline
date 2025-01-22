process SUMMARY_SGB_REP {
    publishDir "${params.outdir}/summary/", mode: 'copy'

    input:
    path cdb
    path sdb
    path mash_chunk_files 
    path wdb
    val class_
    val name
    val version

    output:
    
    
    script:
        """
        summarize_split_clusters.py --cdb ${cdb} --sdb ${sdb} -o .
        cp "clusters_split.tsv" "${name}_${class_}_${version}_clusters_split.tsv"

        mash paste ${name}_${class_}_${version}_all.msh ${mash_chunk_files}/chunk_*/chunk_all.msh
        path "${name}_${class_}_${version}_clusters_split.tsv", emit: summary_sgb

        get_rep_score.py -w ${wdb} -v ${version} -c ${class_} -n ${name}
        """
}