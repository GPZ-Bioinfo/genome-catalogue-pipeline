/*
  Subworkflow to generate the protein databases using mmseq2
*/

include { MMSEQ as MMSEQ_100 } from '../modules/mmseq.nf'
include { MMSEQ as MMSEQ_90 } from '../modules/mmseq.nf'
include { MMSEQ as MMSEQ_50 } from '../modules/mmseq.nf'

workflow MMSEQ_SWF {
    take:
        all_prokka_faa
        mmseq_coverage_threshold
    main:

        proteins_ch = all_prokka_faa

        mmseq_100 = MMSEQ_100(
            proteins_ch,
            channel.value(1.0),
            mmseq_coverage_threshold
        )
        mmseq_90 = MMSEQ_90(
            proteins_ch,
            channel.value(0.90),
            mmseq_coverage_threshold
        )
        mmseq_50 = MMSEQ_50(
            proteins_ch,
            channel.value(0.50),
            mmseq_coverage_threshold
        )
    emit:
        mmseq_90_cluster_rep_faa = mmseq_90.mmseq_cluster_rep_faa
        mmseq_90_cluster_tsv = mmseq_90.mmseq_cluster_tsv
        mmseq_90_tarball = mmseq_90.mmseq_tarball
        mmseq_100_cluster_tsv = mmseq_100.mmseq_cluster_tsv
}
