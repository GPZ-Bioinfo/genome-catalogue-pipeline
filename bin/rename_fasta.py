#!/usr/bin/env python3

import os
import gzip
import logging
import argparse
import pandas as pd

logging.basicConfig(level=logging.INFO)

def write_fasta(oldpath, newpath, accession):
    """
    Rename FASTA file deflines and save the result to a new file.
    
    Parameters:
    oldpath (str): The path to the input file (gzip compressed).
    newpath (str): The path to the output file (gzip compressed).
    accession (str): The prefix for renaming the deflines.
    """
    try:
        with gzip.open(oldpath, "rt") as file_in, open(newpath, "wt") as file_out:
            n = 0
            for line in file_in:
                if line.startswith(">"):
                    n += 1
                    file_out.write(">{}_{}\n".format(accession, n))
                else:
                    file_out.write(line)
    except Exception as e:
        logging.error(f"Error processing file {oldpath} -> {newpath}: {e}")

def rename_to_outdir(filepath, newname, accession, output_dir):
    """
    Rename file and move it to the specified output directory.

    Parameters:
    filepath (str): The original file path.
    newname (str): The new name of the file.
    accession (str): The prefix for renaming.
    output_dir (str): The directory where renamed files will be stored.
    """
    filename = os.path.basename(filepath)
    newpath = os.path.join(output_dir, newname)
    try:
        if not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)  # Create the output directory if not exists
        write_fasta(filepath, newpath, accession)
    except Exception as e:
        logging.error(f"Error renaming file {filepath} to {newname}: {e}")

def print_table(names, table_file):
    """
    Write the mapping of old names to new names into a tab-separated file.

    Parameters:
    names (dict): Dictionary mapping old file names to new file names.
    table_file (str): The file path where the table will be saved.
    """
    try:
        with open(table_file, "w") as table_out:
            table_out.write("old_genome\tnew_genome\n") #as xxxxx.fna.gz xxxxx.fna
            for key, value in names.items():
                table_out.write("{}\t{}\n".format(key, value))
    except Exception as e:
        logging.error(f"Error writing table to {table_file}: {e}")

def merge_metadata(table_file, metadata_file, output_csv):
    """
    Update the metadata file by adding the new genome column based on the mapping table.
    Replace old genome names in the 'representative' column with the new genome names.

    Parameters:
    metadata_file (str): The file path of the metadata TSV file.
    table_file (str): The file path of the table mapping old_genome to new_genome.
    output_file (str): The output file path where the updated CSV will be saved.
    """
    try:
        table_df = pd.read_csv(table_file, sep='\t')
        metadata_df = pd.read_csv(metadata_file, sep='\t')
        table_df['old_genome'] = table_df['old_genome'].apply(lambda x: os.path.basename(x))
        
        if 'representative' not in metadata_df.columns:
            logging.info("No 'representative' column found in the metadata file. Skipping replacement.")
        else:
            
            old_to_new_genome = dict(zip(table_df['old_genome'], table_df['new_genome']))

            metadata_df['representative'] = metadata_df['representative'].apply(
                lambda x: old_to_new_genome.get(x, x)  # If the old_genome is found, replace, else keep the original
            )

        
        metadata_df = metadata_df.rename(columns={"genome": "old_genome"})
        metadata_df = metadata_df.merge(table_df, on="old_genome", how="left")
        metadata_df = metadata_df.rename(columns={"new_genome": "genome"})

        metadata_df.to_csv(output_csv, index=False)

        logging.info(f"Metadata has been updated and saved to {output_csv}")

    except Exception as e:
        logging.error(f"Error processing metadata file: {e}")




def main(input_dir, prefix, index, table_file, output_dir=None, max_number=None, metadata_file=None, output_csv=None):
    """
    Main function to process and rename FASTA files, and generate a mapping table.

    Parameters:
    input_dir (str): The directory containing the input .fna.gz files.
    prefix (str): The prefix used in the new filenames.
    index (int): The starting index for naming files.
    table_file (str): The file path where the table of old and new names will be saved.
    output_dir (str, optional): The directory to move renamed files to.
    max_number (int, optional): The maximum number of files to rename.
    metadata_file (str, optional): Path to the metadata TSV file for merging.
    output_csv (str, optional): Path to save the merged CSV file.
    """
    names = {}
    try:
        files = [os.path.join(input_dir, f) for f in os.listdir(input_dir) if f.endswith(".fna.gz")]
    except FileNotFoundError:
        logging.error(f"The directory {input_dir} was not found.")
        exit(1)
    except Exception as e:
        logging.error(f"Error reading directory {input_dir}: {e}")
        exit(1)

    logging.info("Renaming files...")
    for file in files:
        if file.endswith(".fna.gz"):
            if max_number and index > max_number:
                logging.error("Index exceeds the maximum number of files requested.")
                exit(1)
            accession = "{}{:09d}".format(prefix, index)  # Format the accession with leading zeros
            new_name = "{}.fna".format(accession)
            names[file] = new_name
            index += 1
            if output_dir:
                rename_to_outdir(file, new_name, accession, output_dir)

    logging.info("Printing names to table...")
    print_table(names, table_file)

    if metadata_file and output_csv:
        logging.info("Merging metadata with the renamed files...")
        merge_metadata(table_file, metadata_file, output_csv)

def parse_args():
    """
    Parse command-line arguments using argparse.

    Returns:
    argparse.Namespace: The parsed arguments.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Rename multifasta files, cluster information file, and create a table "
            "matching old and new names. "
            "If you have a map file (genome - old_genome), you can provide it, and "
            "files will be renamed according to this file."
        )
    )
    parser.add_argument(
        "-d", dest="inputdir", required=True, help="Input directory containing .fna.gz files"
    )
    parser.add_argument(
        "-p", dest="prefix", help="Header prefix for renaming"
    )
    parser.add_argument(
        "-i", dest="index", type=int, default=1, help="Index to start naming at (default: 1)"
    )
    parser.add_argument(
        "--max", dest="max", type=int, help="Maximum number of files to process"
    )
    parser.add_argument(
        "-t", dest="table_file", default="namingtable.tsv", help="Output table file (default: naming_table.tsv)"
    )
    parser.add_argument(
        "-o", dest="outputdir", help="Output directory for renamed files"
    )
    parser.add_argument(
        "--metadata", dest="metadatafile", help="Path to the metadata TSV file"
    )
    parser.add_argument(
        "--output_csv", dest="outputcsv", help="Output CSV file for merged metadata"
    )
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    main(
        args.inputdir,
        args.prefix,
        args.index,
        args.table_file,
        output_dir=args.outputdir,
        max_number=args.max,
        metadata_file=args.metadatafile,
        output_csv=args.outputcsv
    )

#python rename_fasta.py -d genomes/ -p BIFIDO -i 1 --max 100 -t name_mapping.tsv -o new_genomes --metadata metadata.tsv --output-csv output.csv