#!/usr/bin/env python3

import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script converts checkm output to csv format"
    )
    parser.add_argument(
        "-i",
        "--input",
        dest="input",
        help="checkm_results.tab (for CheckM) or quality_report.tsv (for CheckM2)",
        required=True,
    )
    parser.add_argument(
        "--checkm2",
        action='store_true',
        help="Use flag if input is produced by CheckM2; default: False",
        default=False,
    )

    args = parser.parse_args()
    
    if args.checkm2:
        print("genome,completeness,contamination")
    else:
        print("genome,completeness,contamination,strain_heterogeneity")

    with open(args.input, "r") as f:
        if args.checkm2:
            next(f)
            for line in f:
                genome, complet, cont = line.split("\t")[:3]
                print("{},{},{}".format(genome, complet, cont))
        else:
            next(f)
            for line in f:
                if "INFO:" in line:
                    continue
                if "Completeness" in line and "Contamination" in line:
                    continue
                cols = line.strip("\n").split("\t")
                genome = cols[0]
                complet = cols[-3]
                cont = cols[-2]
                strain = cols[-1]
                print("{},{},{},{}".format(genome, complet, cont, strain))