#!/usr/bin/env python3
import os
import sys
import argparse

def get_scores(sdb):
    scores = {}
    with open(sdb, "r") as file_in:
        next(file_in)
        for line in file_in:
            values = line.strip().split(",")
            scores.setdefault(values[0], values[1])
    return scores

def get_clusters(clst_file):
    clusters = {}
    with open(clst_file, "r") as f:
        next(f)
        for line in f:
            args = line.rstrip().split(",")
            clusters.setdefault(args[1], []).append(args[0])
    return clusters

def get_cluster_stats(cluster_genomes, genome_scores):
    mag_count = 0
    isolate_count = 0
    for genome in cluster_genomes:
        if float(genome_scores[genome]) > 1000:
            isolate_count += 1
        else:
            mag_count += 1
    return mag_count, isolate_count

def sort_genomes_by_score(genomes, genome_scores):
    sorted_genomes = [
        x
        for _, x in sorted(
            zip(genome_scores, genomes),
            reverse=True,
            key=lambda pair: pair[0],
        )
    ]
    return sorted_genomes

def get_rep(sorted_genomes):
    return sorted_genomes[0]

def determine_rep_type(rep_score):
    if rep_score > 1000:
        return "Isolate"
    else:
        return "MAGs"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Split dRep results by species cluster"
    )
    parser.add_argument(
        "-o", dest="output_folder", help="Output folder [REQUIRED]", required=True
    )
    parser.add_argument(
        "--cdb",
        dest="cdb",
        help="dRep output folder/data_tables/Cdb.csv",
        required=True,
    )
    parser.add_argument("--sdb", dest="sdb", help="dRep Sdb.csv", required=True)

    args = parser.parse_args()

    scores = get_scores(sdb=args.sdb)
    clusters = get_clusters(clst_file=args.cdb)
    names = {True: "one_genome", False: "many_genomes"}

    if not os.path.isdir(args.output_folder):
        os.makedirs(args.output_folder)

    with open(os.path.join(args.output_folder, "clusters_split.tsv"), "w") as split_file:
        split_file.write("cluster_type\tcluster_name\trep_name\trep_type\tcount\tMAGSs_count\tisolate_count\tgenomes\n")
        for c in clusters:
            genomes = clusters[c]
            genome_scores = {genome: float(scores[genome]) for genome in genomes}
            sorted_genomes = sort_genomes_by_score(genomes, genome_scores)
            rep = get_rep(sorted_genomes)
            rep_type = determine_rep_type(float(scores[rep]))
            mag_count, isolate_count = get_cluster_stats(genomes, scores)
            count = len(genomes)
            split_file.write(
                f"{names[count == 1]}\t{c}\t{rep}\t{rep_type}\t{count}\t{mag_count}\t{isolate_count}\t{','.join(sorted_genomes)}\n")


