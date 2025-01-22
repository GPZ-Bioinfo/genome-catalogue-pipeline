#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// input validation
ch_start_number = channel.value(params.start_number)
ch_end_number = channel.value(params.end_number)
ch_sgb_version = channel.value(params.version)
ch_prefix = channel.value(params.genome_prefix)
ch_mmseq_coverage_threshold= channel.value(params.mmseq_coverage_threshold)

// import create catalogue modules
include { RENAME_FASTA } from '../modules/rename_fasta.nf'
include { CHECKM2 } from '../modules/checkm2.nf'
include { QUALITY_CONTROL } from '../modules/qualty_control.nf'
include { DREP_DEDUPLICATE } from '../modules/drep_deduplicate.nf'
include { PREPARE_SGB_INFO } from '../modules/prepare_sgb_info.nf'
include { DREP_SWF } from '../subworkflows/drep_catalog_split_cluster.nf'
include { CLASSIFY_CLUSTERS } from '../modules/classify_clusters.nf'
include { MASH_SKETCH } from '../modules/mash_sketch.nf'

include { GTDBTK_QC } from '../modules/gtdbtk_qc.nf'
include { GTDBTK_TAX } from '../modules/gtdbtk_tax.nf'
include { IQTREE as IQTREE_BAC } from '../modules/iqtree.nf'
include { IQTREE as IQTREE_AR } from '../modules/iqtree.nf'
include { FASTTREE as FASTTREE_BAC } from '../modules/fasttree.nf'
include { FASTTREE as FASTTREE_AR } from '../modules/fasttree.nf'

include { PARSE_DOMAIN } from '../modules/parse_domain'
include { PROCESS_PROKKA } from '../subworkflows/process_prokka.nf'
include { MMSEQ_SWF } from '../subworkflows/mmseq_swf'
include { ANNOTATE } from '../subworkflows/annotate.nf'
include { FUNCTIONAL_ANNOTATION_SUMMARY } from '../modules/functional_summary'
include { ANNOTATE_GFF } from '../modules/annotate_gff'
include { GENE_CATALOGUE } from '../modules/gene_catalogue'

// import genome datasets and input parameters
ch_input_genomes = file(params.input_genomes, checkIfExists: true)
ch_metadata_tsv =file(params.input_genomes_metadata)//*need atleast 2 cols:genome,type



//*If not specified,with warnings and use default parameter
ch_checkm2_db = file(params.checkm2_db)
ch_gtdb_db =file(params.gtdb_db)
ch_interproscan_db = file(params.interproscan_db)
ch_eggnog_db = file(params.eggnog_db)
ch_eggnog_diamond_db = file(params.eggnong_diamond_db)
ch_eggnog_data_dir = file(params.eggnong_data_dir)
ch_dbcan_db = file(params.dbcan_db)
ch_kegg_classes = file(params.kegg_classes)


ch_quality_level = channel.value(params.quality_filter) //default medium
ch_drepcluster_method = channel.value(params.drepcluster_method)// default fastANI

//?add genome extention parameter? now gunzip files with extention.fna;because ANImf only use unzip files
// run workflow
workflow CREATE_CATALOGUE {

    //? Perhaps switching to multi-threaded processing would be better? 
    RENAME_FASTA(
        ch_input_genomes,
        ch_metadata_tsv,
        ch_start_number,
        ch_end_number,
        ch_prefix
    )
    //* Check if skip_checkm2 is false, if so, run CHECKM2 Process to get genome quality
    if (params.run_checkm2) {
        CHECKM2(
            RENAME_FASTA.out.renamed_genomes_folder,
            RENAME_FASTA.out.renamed_genome_metadata_csv,
            ch_checkm2_db,
            ch_prefix
        )
    }   
    //* Quality control process uses quality level to filter genomes ('high' or 'medium')
    if (params.run_checkm2) {
        new_metadata_csv = CHECKM2.out.genomes_add_checkm_metadata_csv
    } else {
        new_metadata_csv = RENAME_FASTA.out.renamed_genome_metadata_csv
    }

    QUALITY_CONTROL(
        new_metadata_csv,
        RENAME_FASTA.out.renamed_genomes_folder,
        ch_quality_level,
        ch_prefix
    )

    //* Genome deduplication by MASH sketch 10^4
    DREP_DEDUPLICATE(
        QUALITY_CONTROL.out.passqc_genomes_folder,
        QUALITY_CONTROL.out.passqc_checkm_csv,
        QUALITY_CONTROL.out.extra_weighted_tsv
    )

    PREPARE_SGB_INFO(
        DREP_DEDUPLICATE.out.dereplicated_genomes,
        DREP_DEDUPLICATE.out.derep_genomeInfo,
        QUALITY_CONTROL.out.extra_weighted_tsv,
        ch_prefix
    )

    //* No add Mgnify DREP_LARGE_SWF (for genomes > 100k, Mgnify split into chunks each 25000 genomes)
    DREP_SWF(
        DREP_DEDUPLICATE.out.dereplicated_genomes,
        PREPARE_SGB_INFO.out.catalog_genomeinfo_csv,
        PREPARE_SGB_INFO.out.catalog_extra_weighted_tsv,
        ch_drepcluster_method
    )

    if (params.input_cluster_split) {
        ch_input_cluster_split = file(params.input_cluster_split)
        drep_split_text = ch_input_cluster_split
    } else {
        drep_split_text = DREP_SWF.out.drep_split_text
    }

    CLASSIFY_CLUSTERS(
            DREP_DEDUPLICATE.out.dereplicated_genomes,
            drep_split_text
        )

    groupGenomes = { fna_file ->
            def cluster = fna_file.parent.toString().tokenize("/")[-1]
            return tuple(cluster, fna_file)
    }    

    many_genomes_fna_tuples = CLASSIFY_CLUSTERS.out.many_genomes_fnas | flatten | map(groupGenomes)
    single_genomes_fna_tuples = CLASSIFY_CLUSTERS.out.one_genome_fnas | flatten | map(groupGenomes)
    all_genomes_fna_tuples = CLASSIFY_CLUSTERS.out.all_genome_fnas | flatten | map(groupGenomes)

    rep_genomes_fna = single_genomes_fna_tuples.map({ it[1] }).mix(many_genomes_fna_tuples.filter { it[1].name.contains(it[0]) }.map({ it[1] })).collect()

    MASH_SKETCH(
        all_genomes_fna_tuples.map({ it[1] }).collect()//refine
    )

    //*?check domains by gtdb,useless since running mag or choose specific genus genome
    //*?but check chongqing results with "Archaea" genomes so keep this process or can later change input_metadata add domains data col
    GTDBTK_QC(
        rep_genomes_fna,
        channel.value("fna"), // genome file extension
        ch_gtdb_db
    )

    gtdbtk_tables_qc_ch = channel.empty() \
        .mix(GTDBTK_QC.out.gtdbtk_summary_bac120, GTDBTK_QC.out.gtdbtk_summary_arc53) \
        .collectFile(name: 'gtdbtk.summary.tsv')
    
    PARSE_DOMAIN(
        gtdbtk_tables_qc_ch,
        drep_split_text
    )

    accessions_with_domains_ch = PARSE_DOMAIN.out.detected_domains.flatMap { file ->
        file.readLines().collect { line ->
            def (genomeName, domain) = line.split(',')
            [genomeName, domain]
        }
    }
    
    if (!params.skip_annotation) {
        //*?no add many_genomes_fna_tuples each cluster PANAROO dif from Mgnify
        //*?no add singleton run GUNC
        PROCESS_PROKKA(
            all_genomes_fna_tuples,
            accessions_with_domains_ch
        )
        //*?need to assign a Uniref90-ID later
        MMSEQ_SWF(
            PROCESS_PROKKA.out.prokka_faas.map({ it[1] }).collectFile(name: "all_prokka.faa"),
            ch_mmseq_coverage_threshold
        )
        cluster_reps_faas = PROCESS_PROKKA.out.rep_prokka_faa
        cluster_reps_fnas = PROCESS_PROKKA.out.rep_prokka_fna
        cluster_reps_gbks = PROCESS_PROKKA.out.rep_prokka_gbk
        cluster_reps_gffs = PROCESS_PROKKA.out.rep_prokka_gff
        all_prokka_fna = PROCESS_PROKKA.out.prokka_fnas

        species_reps_names_list = PROCESS_PROKKA.out.rep_prokka_fna.map({ it[0] }) \
            .collectFile(name: "species_reps_names_list.txt", newLine: true)

        ANNOTATE(
            MMSEQ_SWF.out.mmseq_90_cluster_tsv,
            MMSEQ_SWF.out.mmseq_90_tarball,
            MMSEQ_SWF.out.mmseq_90_cluster_rep_faa,
            all_prokka_fna,
            cluster_reps_gbks,
            cluster_reps_faas,
            cluster_reps_gffs,
            species_reps_names_list,
            ch_interproscan_db,
            ch_eggnog_db,
            ch_eggnog_diamond_db,
            ch_eggnog_data_dir,
            ch_dbcan_db
        )

        cluster_reps_faa = PROCESS_PROKKA.out.rep_prokka_faa

        faa_and_annotations = cluster_reps_faa.join(
            ANNOTATE.out.ips_annotation_tsvs
        ).join(
            ANNOTATE.out.eggnog_annotation_tsvs
        )

        FUNCTIONAL_ANNOTATION_SUMMARY(
            faa_and_annotations,
            ch_kegg_classes
        )

        cluster_reps_gff = PROCESS_PROKKA.out.rep_prokka_gff

        // Select the only the reps //
        // Those where the cluster-name and the file name match
        // i.e., such as cluster_name: MGY1 and file MGY1_eggnog.tsv
        reps_ips = ANNOTATE.out.ips_annotation_tsvs.filter {
            it[1].name.contains(it[0])
        }
        reps_eggnog = ANNOTATE.out.eggnog_annotation_tsvs.filter {
            it[1].name.contains(it[0])
        }

        // REPS //
        ANNOTATE_GFF(
            cluster_reps_gff.join(
                reps_eggnog
            ).join(
                ANNOTATE.out.dbcan_gffs, remainder: true
            ).join(
                reps_ips
            )
        )

        cluster_rep_ffn = PROCESS_PROKKA.out.rep_prokka_ffn

        GENE_CATALOGUE(
            cluster_rep_ffn.map({ it[1] }).collectFile(name: "cluster_reps.ffn", newLine: true),
            MMSEQ_SWF.out.mmseq_100_cluster_tsv
        )
    }
    if (!params.skip_gtdb) {
        // Separate accessions into those we don't know domain for (Undefined) and those that we do
        accessions_with_domains_ch
        .branch {
            defined: it[1] != "Undefined"
            return it[0]
            undefined: it[1] == "Undefined"
            return it[0]
        }
        .set { domain_splits }
        // Add "to_remove" to accessions that have an undefined domain
        undefined_genomes = domain_splits.undefined.map(it -> [it, "to_remove"])

        filtered_single_genome_fna_tuples = single_genomes_fna_tuples \
            .join(undefined_genomes, remainder: true) \
            .filter { genome_name, fa_path, remove_flag -> remove_flag == null} \
            .map { genome_name, fa_path, remove_flag -> [genome_name, fa_path] }
        
        GTDBTK_TAX(
            filtered_single_genome_fna_tuples 
            .map({ it[1] }) 
            .mix( 
                many_genomes_fna_tuples 
                    .filter { 
                        it[1].name.contains(it[0])
                    }
                    .map({ it[1] })
            ) 
            .collect(),
            channel.value("fna"), // genome file extension
            ch_gtdb_db,
            undefined_genomes.count(),
            GTDBTK_QC.out.gtdbtk_summary_bac120.ifEmpty(file("EMPTY")),
            GTDBTK_QC.out.gtdbtk_summary_arc53.ifEmpty(file("EMPTY")),
            GTDBTK_QC.out.gtdbtk_user_msa_bac120.ifEmpty(file("EMPTY")),
            GTDBTK_QC.out.gtdbtk_user_msa_ar53.ifEmpty(file("EMPTY")),
            GTDBTK_QC.out.gtdbtk_output_tarball
        )

        gtdbtk_tables_ch = channel.empty() \
            .mix(GTDBTK_TAX.out.gtdbtk_summary_bac120, GTDBTK_TAX.out.gtdbtk_summary_arc53) \
            .collectFile(name: 'gtdbtk.summary.tsv')
        }

    if (!params.skip_gtdb && !params.skip_tree) {
        //IQTree needs at least 3 sequences, but it's too slow for more than 2000 sequences so we use FastTree in that case/
        def treeCreationCriteria = branchCriteria {
            iqtree: file(it).countFasta() > 2 && file(it).countFasta() < 2000
            fasttree: file(it).countFasta() >= 2000  
        }
        GTDBTK_TAX.out.gtdbtk_user_msa_bac120.branch( treeCreationCriteria ).set { gtdbtk_user_msa_bac120 }
        
        IQTREE_BAC(
        gtdbtk_user_msa_bac120.iqtree,
        channel.value("bac120")
        )
        FASTTREE_BAC(
        gtdbtk_user_msa_bac120.fasttree,
        channel.value("bac120")
        )

        GTDBTK_TAX.out.gtdbtk_user_msa_ar53.branch( treeCreationCriteria ).set{ gtdbtk_user_msa_ar53 }

        IQTREE_AR(
            gtdbtk_user_msa_ar53.iqtree,
            channel.value("ar53")
        )
        FASTTREE_AR(
            gtdbtk_user_msa_ar53.fasttree,
            channel.value("ar53")
        )
    }
}
