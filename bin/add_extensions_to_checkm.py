#!/usr/bin/env python3

import argparse
import os

def main(fasta_file_directory, checkm_directory):
    fasta_dict = load_file_list(fasta_file_directory)
    checkm_path = os.path.join(checkm_directory, "quality_report.tsv")
    assert os.path.isfile(checkm_path), "CheckM2 input doesn't exist"
    contents = ""
    with open(checkm_path, "r") as file_in:
        for line in file_in:
            if "Completeness" in line:
                contents += line
            else:
                genome_name = line.split("\t")[0]
                genome_with_ext = fasta_dict[genome_name]
                line = line.replace(genome_name, genome_with_ext)
                contents += line
    with open(checkm_path, "w") as file_out:
        file_out.write(contents)
        
    
def load_file_list(fasta_file_directory):
    fasta_dict = dict()
    file_list = os.listdir(fasta_file_directory)
    for file in file_list:
        name = file.rsplit(".", 1)[0] #*now results with .fna and file with .fna
        fasta_dict[name] = file
    return fasta_dict
        
    
def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "The script processes CheckM2 output to put the genome file extensions back in."
        )
    )
    parser.add_argument(
        "-d",
        dest="fasta_file_directory",
        required=True,
        help="Input directory containing FASTA files",
    )
    parser.add_argument(
        "-i",
        dest="checkm_directory",
        help=(
            "Folder containing output of checkm2"
        ),
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    main(
        args.fasta_file_directory,
        args.checkm_directory,
    )