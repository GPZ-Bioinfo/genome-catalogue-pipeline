#!/usr/bin/env python3

import os
import pandas as pd
import argparse


def extract_genome_info(dereplicated_genomes, genomeinfo, catalogue_genomeinfo_csv):
    """
    Extracts genome information (completeness and contamination) from the given genomeinfo file for 
    genomes present in the dereplicated_genomes folder and saves it to a CSV file.

    Args:
        dereplicated_genomes (str): Path to the folder containing the dereplicated genomes.
        genomeinfo (str): Path to the genomeinfo CSV file containing genome details.
        catalogue_genomeinfo_csv (str): Path to the output CSV file for storing the extracted genome information.
    """

    file_names = os.listdir(dereplicated_genomes)
    df = pd.read_csv(genomeinfo)
    result_df = pd.DataFrame(columns=['genome', 'completeness', 'contamination'])
    for file_name in file_names:
        genome_row = df[df['genome'] == file_name]
        
        if not genome_row.empty:
            result_df = pd.concat([result_df, genome_row[['genome', 'completeness', 'contamination']]], ignore_index=True)
    
    result_df.to_csv(catalogue_genomeinfo_csv, index=False)



def find_matching_rows(genomeinfo, extra_weights, catalogue_extra_weight_tsv):
    """
    Finds matching rows between genomeinfo and extra_weights files and saves them to a TSV file.

    Args:
        genomeinfo (str): Path to the genomeinfo CSV file.
        extra_weights (str): Path to the extra_weights TSV file.
        catalogue_extra_weight_tsv (str): Path to the output TSV file for storing the matching rows.
    """
    df_csv = pd.read_csv(genomeinfo)
    df_tsv = pd.read_csv(extra_weights, sep='\t', header=None, names=['genome', 'additional_info'])
    matching_rows = df_tsv[df_tsv['genome'].isin(df_csv['genome'])]
    matching_rows.to_csv(catalogue_extra_weight_tsv, sep='\t', header=None, index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract and match deduplicated genome data')
    parser.add_argument('-g', '--dereplicated_genomes', type=str, help='Path to the dereplicated genomes directory')
    parser.add_argument('-i', '--genomeinfo', type=str, help='Path to the genomeinfo CSV file')
    parser.add_argument('-e', '--extra_weights', help='Path to the extra_weights TSV file')
    parser.add_argument('-og', '--catalogue_genomeinfo_csv', help='Path to the output CSV file for catalogue genome info')
    parser.add_argument('-oe', '--output_catalogue_extra_weight_tsv', help='Path to the output TSV file for catalogue extra weights')
    args = parser.parse_args()

    extract_genome_info(args.dereplicated_genomes, args.genomeinfo, args.catalogue_genomeinfo_csv)
    find_matching_rows(args.genomeinfo, args.extra_weights, args.output_catalogue_extra_weight_tsv)
