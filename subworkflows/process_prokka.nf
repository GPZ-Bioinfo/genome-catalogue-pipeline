/*
 * Process prokka with all new_name genomes
*/

include { PROKKA } from '../modules/prokka.nf'


workflow PROCESS_PROKKA {
    take:
        all_genomes_clusters// list<tuple(cluster_name, genome_fna)>
        accessions_with_domains_tuples// tuple( mgyg_accession, domain ) - the domain is either "Bacteria", "Archaea" or "Undefined"
    main:

        PROKKA(
            all_genomes_clusters.combine(accessions_with_domains_tuples)
            .filter { genome_name_fa, fa_path, genome_name_domain, domain -> genome_name_fa == genome_name_domain }
            .map { genome_name_fa, fa_path, genome_name_domain, domain -> [genome_name_fa, fa_path, domain] }
        )

        rep_prokka_gff = PROKKA.out.gff.filter {
            it[1].name.contains(it[0])
        }
        rep_prokka_faa = PROKKA.out.faa.filter {
            it[1].name.contains(it[0])
        }
        rep_prokka_fna = PROKKA.out.fna.filter {
            it[1].name.contains(it[0])
        }
        rep_prokka_gbk = PROKKA.out.gbk.filter {
            it[1].name.contains(it[0])
        }
        rep_prokka_ffn = PROKKA.out.ffn.filter {
            it[1].name.contains(it[0])
        }
        non_rep_prokka_gff = PROKKA.out.gff.filter {
            !it[1].name.contains(it[0])
        }
        non_rep_prokka_fna = PROKKA.out.fna.filter {
            !it[1].name.contains(it[0])
        }

    emit:
        prokka_faas = PROKKA.out.faa
        prokka_fnas = PROKKA.out.fna
        prokka_gffs = PROKKA.out.gff
        rep_prokka_fna = rep_prokka_fna
        rep_prokka_gff = rep_prokka_gff
        rep_prokka_faa = rep_prokka_faa
        rep_prokka_gbk = rep_prokka_gbk
        rep_prokka_ffn = rep_prokka_ffn
        non_rep_prokka_fna = non_rep_prokka_fna
        non_rep_prokka_gff = non_rep_prokka_gff
}
