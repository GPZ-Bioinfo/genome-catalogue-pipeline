#!/usr/bin/env python3

import os
import shutil
import argparse
import sys

NAME_MASH = "mash_folder"
NAME_MANY_GENOMES = "many_genomes"
NAME_ONE_GENOME = "one_genome"
NAME_ALL_GENOMES = "all_genomes"


def classify_splitted_folders(input_folder):
    if not os.path.exists(NAME_MASH):
        os.makedirs(NAME_MASH)

    drep_clusters = input_folder
    clusters = os.listdir(drep_clusters)
    for cluster in clusters:
        dir_files = os.listdir(os.path.join(drep_clusters, cluster))
        genomes = [i for i in dir_files if i.endswith(".fna")] 
        #*genome extention with ".fna"; mgnify default input use .fa
        number_of_genomes = len(genomes)
        path_cluster_many = os.path.join(NAME_MANY_GENOMES, cluster)
        path_cluster_one = os.path.join(NAME_ONE_GENOME, cluster)

        if number_of_genomes > 1:
            if not os.path.exists(path_cluster_many):
                os.makedirs(path_cluster_many)
            for genome in genomes:
                old_path = os.path.join(drep_clusters, cluster, genome)
                new_path = os.path.join(path_cluster_many, genome)
                shutil.copy(old_path, new_path)
            mashes = [i for i in dir_files if i.endswith("mash.tsv")]
            if len(mashes) > 0:
                mash = mashes[0]
                shutil.copy(
                    os.path.join(drep_clusters, cluster, mash),
                    os.path.join(NAME_MASH, mash),
                )
        if number_of_genomes == 1:
            if not os.path.exists(path_cluster_one):
                os.makedirs(path_cluster_one)
            for genome in genomes:
                old_path = os.path.join(drep_clusters, cluster, genome)
                new_path = os.path.join(path_cluster_one, genome)
                shutil.copy(old_path, new_path)


def classify_by_file(split_text, genomes_folder):
    with open(split_text, "r") as file_in:
        next(file_in)
        for line in file_in:
            main_folder, cluster_name,genome_counts,genomes_str = line.strip().split("\t") #*use tab ; mgnify default use ":"
            genomes = genomes_str.split(",")
            cluster_name = genomes[0].split(".")[0]  # cluster 
            path_cluster = os.path.join(main_folder, cluster_name)
            if not os.path.exists(path_cluster):
                os.mkdir(path_cluster)
            for genome in genomes:
                old_path = os.path.join(genomes_folder, genome)
                new_path = os.path.join(path_cluster, genome)
                shutil.copy(old_path, new_path)

def combine_genomes_to_all():
    if not os.path.exists(NAME_ALL_GENOMES):
        os.makedirs(NAME_ALL_GENOMES)
    
    if os.path.exists(NAME_MANY_GENOMES):
        for cluster in os.listdir(NAME_MANY_GENOMES):
            source_path = os.path.join(NAME_MANY_GENOMES, cluster)
            destination_path = os.path.join(NAME_ALL_GENOMES, cluster)
            if not os.path.exists(destination_path):
                os.makedirs(destination_path)
            for file in os.listdir(source_path):
                shutil.copy(os.path.join(source_path, file), destination_path)

    if os.path.exists(NAME_ONE_GENOME):
        for cluster in os.listdir(NAME_ONE_GENOME):
            source_path = os.path.join(NAME_ONE_GENOME, cluster)
            destination_path = os.path.join(NAME_ALL_GENOMES, cluster)
            if not os.path.exists(destination_path):
                os.makedirs(destination_path)
            for file in os.listdir(source_path):
                shutil.copy(os.path.join(source_path, file), destination_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Moves clusters according the number of genomes"
    )
    parser.add_argument(
        "-i",
        "--input",
        dest="input_folder",
        help="drep_split out folder",
        required=False,
    )
    parser.add_argument(
        "--text-file", dest="text_file", help="drep_split out txt file", required=False
    )
    parser.add_argument(
        "-g",
        "--genomes",
        dest="genomes",
        help="folder with all genomes",
        required=False,
    )

    if len(sys.argv) == 1:
        parser.print_help()
    else:
        args = parser.parse_args()
        if not (args.input_folder or args.text_file):
            print("No necessary arguments specified")
            exit(1)

        if not os.path.exists(NAME_MANY_GENOMES):
            os.makedirs(NAME_MANY_GENOMES)
        if not os.path.exists(NAME_ONE_GENOME):
            os.makedirs(NAME_ONE_GENOME)

        if args.input_folder:
            print("Classify splitted folders")
            classify_splitted_folders(args.input_folder)
        elif args.text_file:
            if args.genomes:
                classify_by_file(split_text=args.text_file, genomes_folder=args.genomes)
            else:
                print("No -g specified")

    combine_genomes_to_all()