#!/usr/bin/env python3
import os
import shutil
import pandas as pd
import argparse

def assign_weight(Genome_id_type):
    """
    Assigns a weight based on the Genome ID type. 

    Args:
        Genome_id_type (str): The type of the genome ID (e.g., "Isolate", "MAG").

    Returns:
        str: The weight assigned to the genome ID type.
    
    Raises:
        ValueError: If the Genome_id_type is unknown.
    """
    if Genome_id_type.lower().startswith("isolate"):
        weight = "1000"  # Isolates get a weight of 1000
    elif Genome_id_type.upper().startswith("MAG"):
        weight = "0"  # MAGs get a weight of 0
    else:
        raise ValueError(f"Unknown Genome_id type: {Genome_id_type}")
    return weight

def determine_quality(completeness, contamination):
    """
    Determines the quality of the genome based on completeness and contamination levels.

    Args:
        completeness (float): Completeness of the genome (0-100).
        contamination (float): Contamination of the genome (0-100).
    
    Returns:
        str: Quality level ('high', 'medium', 'not_pass').
    """
    if completeness > 90 and contamination < 5:
        return 'high'
    elif completeness > 50 and contamination < 5 and (completeness - 5 * contamination > 50):
        return 'medium'
    else:
        return 'not_pass'

def add_quality_and_move_files(metadata_df_file, renamed_genomes_folder, quality_level, output_folder, output_metadata_file, output_checkm_file,output_extra_weight_file):
    """
    Adds quality information to metadata, filters genomes based on quality level, and moves files to output folder.
    
    Args:
        metadata_df_file (str): Path to the input metadata CSV file.
        renamed_genomes_folder (str): Path to the folder containing the renamed genome files.
        quality_level (str): Quality level to filter genomes ('high' or 'medium').
        output_folder (str): Path to the folder to save filtered genome files.
        output_metadata_file (str): Path to save the updated metadata CSV.
        output_extra_weight_file (str): Path to save the extra weight information (tab-delimited).
    """
    metadata_df = pd.read_csv(metadata_df_file)
    metadata_df['quality'] = metadata_df.apply(
        lambda row: determine_quality(row['completeness'], row['contamination']),
        axis=1
    )

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    for index, row in metadata_df.iterrows():
        genome = row['genome']
        genome_file = os.path.join(renamed_genomes_folder, genome)

        if os.path.exists(genome_file):
            # Copy file if it meets quality conditions
            if quality_level == 'high' and row['quality'] == 'high':
                shutil.copy(genome_file, os.path.join(output_folder, genome))
            elif quality_level == 'medium' and row['quality'] in ['high', 'medium']:
                shutil.copy(genome_file, os.path.join(output_folder, genome))

    metadata_df.to_csv(output_metadata_file, index=False)
    if quality_level == 'high':
        filtered_df = metadata_df[metadata_df['quality'] == 'high']
    elif quality_level == 'medium':
        filtered_df = metadata_df[metadata_df['quality'].isin(['high', 'medium'])]

    filtered_df[['genome', 'completeness', 'contamination']].to_csv(output_checkm_file, index=False)
    extra_weights_df = filtered_df[['genome', 'type']].apply(
        lambda x: pd.Series([x['genome'], assign_weight(x['type'])]), axis=1
    )
    extra_weights_df.to_csv(output_extra_weight_file, sep='\t', index=False, header=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process quality control genome files and update metadata.")
    parser.add_argument('-m', "--metadata_df_file", type=str, required=True, help="Path to the metadata CSV file.")
    parser.add_argument('-id', "--renamed_genomes_folder", type=str, required=True, help="Path to the folder containing renamed genome files.")
    parser.add_argument('-q', "--quality_level", choices=["high", "medium"], required=True, help="Quality level to filter genomes (high or medium).")
    parser.add_argument("--output_folder", type=str, required=True, help="Path to the folder to save filtered files.")
    parser.add_argument("--output_metadata_file", type=str, required=True, help="Path to the file to save updated metadata.")
    parser.add_argument("--output_checkm_file", type=str, required=True, help="Path to the file to save updated checkm results.")
    parser.add_argument("--output_extra_weight_file", type=str, required=True, help="Path to the file to save extra weight info.")

    args = parser.parse_args()

    add_quality_and_move_files(
        args.metadata_df_file, 
        args.renamed_genomes_folder, 
        args.quality_level, 
        args.output_folder, 
        args.output_metadata_file,
        args.output_checkm_file,
        args.output_extra_weight_file
    )
