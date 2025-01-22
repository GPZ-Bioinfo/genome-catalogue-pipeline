/*
 * dRep get SGB
 */

include { DREP_CATALOG } from '../modules/drep_catalog.nf'
include { DREP_RECLUSTER } from '../modules/drep_recluster.nf'
include { GET_NEW_CDB } from '../modules/recluster_new_cdb.nf'
include { SPLIT_DREP } from '../modules/split_drep.nf'
include { CLASSIFY_CLUSTERS } from '../modules/classify_clusters.nf'

params.run_recluster = params.run_recluster ?: 'false'
//*add parameters recluster
workflow DREP_SWF {
    take:
        dereplicated_genomes
        catalog_genomeinfo_csv
        catalog_extra_weighted_tsv
        ch_drepcluster_method
    main:

        DREP_CATALOG(
            dereplicated_genomes,
            catalog_genomeinfo_csv,
            catalog_extra_weighted_tsv,
            ch_drepcluster_method
        )
        //* Conditionally run reclustering if required
        if (params.run_recluster.toBoolean()) {
            DREP_RECLUSTER(DREP_CATALOG.out.rep_genomes)
            GET_NEW_CDB(
                DREP_CATALOG.out.catalog_cdb_csv,
                DREP_RECLUSTER.out.recluster_cdb_csv
            )
            new_cdb_csv = GET_NEW_CDB.out.new_cdb_csv
            cluster_rep_genomes_fna = DREP_RECLUSTER.out.recluster_rep_genomes
        } else {
            new_cdb_csv = DREP_CATALOG.out.catalog_cdb_csv
            cluster_rep_genomes_fna = DREP_CATALOG.out.rep_genomes
        }

        SPLIT_DREP(
            new_cdb_csv,
            DREP_CATALOG.out.mdb_csv,
            DREP_CATALOG.out.sdb_csv,
        )

    emit:

        drep_split_text = SPLIT_DREP.out.text_split
        mash_splits = SPLIT_DREP.out.mash_splits

}