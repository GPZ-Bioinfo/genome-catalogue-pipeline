#!/usr/bin/env python3

import pandas as pd
import argparse

def add_metadata_results(checkm_result_file: str, input_metadate_file: str, output_file: str) -> None:
    """
    Process CheckM results and merge with additional metadata based on 'Genome'.

    Args:
        checkm_result_file (str): Path to the CheckM results file containing 'Genome', 'Completeness', 'Contamination'.
        input_metadate_file (str): Path to the raw metadata file containing 'Genome' and other columns.
        output_file (str): Path to the output file.

    Returns:
        None
    """
    checkm_df = pd.read_csv(checkm_result_file)
    checkm_df = checkm_df[['genome', 'completeness', 'contamination']]
    metadata_df = pd.read_csv(input_metadate_file)
    metadata_df = metadata_df.drop(columns=['completeness', 'contamination'], errors='ignore')
    merged_df = pd.merge(checkm_df, metadata_df, on='genome', how='inner')
    merged_df.to_csv(output_file, index=False)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Merge CheckM and metadata files based on Genome.')
    parser.add_argument('-cm', '--checkm_result_file', type=str, required=True, help='Path to the CheckM results file.')
    parser.add_argument('-i', '--input_file', type=str, required=True, help='Path to the raw metadata file.')
    parser.add_argument('-o', '--output_file', type=str, required=True, help='Path to the output file.')
    
    args = parser.parse_args()

    add_metadata_results(args.checkm_result_file, args.input_file, args.output_file)
