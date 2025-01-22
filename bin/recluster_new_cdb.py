#!/usr/bin/env python3

import pandas as pd
import argparse

def update_clusters(catalog_cdb_csv, recluster_cdb_csv, output_file):
    
    old_clusters = pd.read_csv(catalog_cdb_csv)
    representative_genomes = pd.read_csv(recluster_cdb_csv)

    
    representative_genomes.rename(columns={'secondary_cluster': 'new_cluster'}, inplace=True)
    old_clusters.rename(columns={'secondary_cluster': 'old_cluster'}, inplace=True)

    
    genome_to_new_cluster = dict(zip(representative_genomes['genome'], representative_genomes['new_cluster']))
    old_clusters_grouped = old_clusters.groupby('old_cluster')['genome'].apply(list).to_dict()

    old_clusters['new_cluster'] = None
    
    for old_cluster, genomes in old_clusters_grouped.items():
        representative_genome = [genome for genome in genomes if genome in genome_to_new_cluster]
        if representative_genome:
            new_cluster = genome_to_new_cluster[representative_genome[0]]
            old_clusters.loc[old_clusters['genome'].isin(genomes), 'new_cluster'] = new_cluster
    old_clusters = old_clusters[['genome', 'new_cluster', 'threshold','cluster_method','comparison_algorithm','primary_cluster','old_cluster']]
    old_clusters.to_csv(output_file, index=False)
def parse_args():
    parser = argparse.ArgumentParser(description='Update old cluster file with new cluster information.')
    parser.add_argument('-old','--catalog_cdb_csv', help='Path to the catalog_cdb_csv')
    parser.add_argument('-new','--recluster_cdb_csv', help='Path to the recluster_cdb_csv')
    parser.add_argument('-o','--output_file', help='Path to the output file to save updated clusters')
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()
    update_clusters(args.catalog_cdb_csv, args.recluster_cdb_csv, args.output_file)
