#!/usr/bin/env python3

# -*- coding: utf-8 -*-

# Copyright 2023 EMBL - European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import argparse
import sys


def main(
    gff,
    ipr_file,
    eggnog_file,
    dbcan_file,
    outfile,
):
    
    header, main_gff_extended, fasta = load_annotations(
        gff,
        eggnog_file,
        ipr_file,
        dbcan_file
    )

    write_results_to_file(
        outfile, header, main_gff_extended, fasta
    )


def write_results_to_file(
    outfile, header, main_gff_extended, fasta, ncrnas=None, trnas=None, crispr_annotations=None
):
    # 设置默认值为空字典，防止为空时出错
    if ncrnas is None:
        ncrnas = {}
    if trnas is None:
        trnas = {}
    if crispr_annotations is None:
        crispr_annotations = {}

    with open(outfile, "w") as file_out:
        file_out.write("\n".join(header) + "\n")
        contig_list = list(main_gff_extended.keys())
        
        # check if there are any contigs that don't have CDS; if so add them in
        contig_list = check_for_additional_keys(ncrnas, trnas, crispr_annotations, contig_list)
        
        for contig in contig_list:
            # 获取排序后的位点列表
            sorted_pos_list = sort_positions(contig, main_gff_extended, ncrnas, trnas, crispr_annotations)
            
            for pos in sorted_pos_list:
                # 迭代不同的字典，检查是否包含对应的 contig 和 pos
                for my_dict in (ncrnas, trnas, crispr_annotations, main_gff_extended):
                    if contig in my_dict and pos in my_dict[contig]:
                        # 遍历并写入行数据
                        for line in my_dict[contig][pos]:
                            if isinstance(line, str):
                                file_out.write("{}\n".format(line))
                            else:
                                for element in line:
                                    file_out.write("{}\n".format(element))
        
        # 写入FASTA数据
        for line in fasta:
            file_out.write("{}\n".format(line))


def sort_positions(contig, main_gff_extended, ncrnas, trnas, crispr_annotations):
    sorted_pos_list = list()
    
    # 遍历所有字典并收集 contig 中的位点
    for my_dict in (main_gff_extended, ncrnas, trnas, crispr_annotations):
        if contig in my_dict:
            sorted_pos_list += list(my_dict[contig].keys())
    
    # 返回去重后的排序位置列表
    return sorted(list(set(sorted_pos_list)))


def check_for_additional_keys(ncrnas, trnas, crispr_annotations, contig_list):
    # 确保每个字典都被处理为非空字典
    for my_dict in (ncrnas, trnas, crispr_annotations):
        dict_keys = set(my_dict.keys())
        absent_keys = dict_keys - set(contig_list)
        
        # 如果有缺少的contig，添加到 contig_list
        if absent_keys:
            contig_list += list(absent_keys)
    
    return contig_list



def get_iprs(ipr_annot):
    iprs = {}
    if not ipr_annot:
        return iprs
    with open(ipr_annot, "r") as f:
        for line in f:
            cols = line.strip().split("\t")
            protein = cols[0]
            try:
                evalue = float(cols[8])
            except ValueError:
                continue
            if evalue > 1e-10:
                continue
            if protein not in iprs:
                iprs[protein] = [set(), set()]
            if cols[3] == "Pfam":
                pfam = cols[4]
                iprs[protein][0].add(pfam)
            if len(cols) > 12:
                ipr = cols[11]
                if not ipr == "-":
                    iprs[protein][1].add(ipr)
    return iprs


def get_eggnog(eggnog_annot):
    eggnogs = {}
    with open(eggnog_annot, "r") as f:
        for line in f:
            line = line.rstrip()
            cols = line.split("\t")
            if line.startswith("#"):
                eggnog_fields = get_eggnog_fields(line)
            else:
                try:
                    evalue = float(cols[2])
                except ValueError:
                    continue
                if evalue > 1e-10:
                    continue
                protein = cols[0]
                eggnog = [cols[1]]

                cog = list(cols[eggnog_fields["cog_func"]])
                if len(cog) > 1:
                    cog = ["R"]

                kegg = cols[eggnog_fields["KEGG_ko"]].split(",")
                # Todo: I added splitting to GO, check that I don't break anything later on
                go = cols[eggnog_fields["GOs"]].split(",")
                eggnogs[protein] = [eggnog, cog, kegg, go]
    return eggnogs


def get_eggnog_fields(line):
    cols = line.strip().split("\t")
    try:
        index_of_go = cols.index("GOs")
    except ValueError:
        sys.exit("Cannot find the GO terms column.")
    if cols[8] == "KEGG_ko" and cols[15] == "CAZy":
        eggnog_fields = {"KEGG_ko": 8, "cog_func": 20, "GOs": index_of_go}
    elif cols[11] == "KEGG_ko" and cols[18] == "CAZy":
        eggnog_fields = {"KEGG_ko": 11, "cog_func": 6, "GOs": index_of_go}
    else:
        sys.exit("Cannot parse eggNOG - unexpected field order or naming")
    return eggnog_fields


def get_dbcan(dbcan_file):
    dbcan_annotations = dict()
    substrates = dict()
    if not dbcan_file:
        return dbcan_annotations
    with open(dbcan_file, "r") as f:
        for line in f:
            if "predicted PUL" in line:
                annot_fields = line.strip().split("\t")[8].split(";")
                for a in annot_fields:
                    if a.startswith("ID="):
                        cgc = a.split("=")[1]
                    elif a.startswith("substrate_dbcan-pul"):
                        substrate_pul = a.split("=")[1]
                    elif a.startswith("substrate_dbcan-sub"):
                        substrate_ecami = a.split("=")[1]
                substrates.setdefault(cgc, {})["substrate_ecami"] = substrate_ecami
                substrates.setdefault(cgc, {})["substrate_pul"] = substrate_pul
            elif line.startswith("#"):
                continue
            else:
                cols = line.strip().split("\t")
                prot_type = cols[2]
                annot_fields = cols[8].split(";")
                if not prot_type == "null":
                    for a in annot_fields:
                        if a.startswith("ID"):
                            acc = a.split("=")[1]
                        elif a.startswith("protein_family"):
                            prot_fam = a.split("=")[1]
                        elif a.startswith("Parent"):
                            parent = a.split("=")[1]
                    dbcan_annotations[acc] = (
                        "dbcan_prot_type={};dbcan_prot_family={};substrate_dbcan-pul={};substrate_dbcan-sub={}".format(
                            prot_type,
                            prot_fam,
                            substrates[parent]["substrate_pul"],
                            substrates[parent]["substrate_ecami"],
                        )
                    )
    return dbcan_annotations



def load_annotations(
    in_gff,
    eggnog_file,
    ipr_file,
    dbcan_file,
):
    eggnogs = get_eggnog(eggnog_file)
    iprs = get_iprs(ipr_file)
    dbcan_annotations = get_dbcan(dbcan_file)
    added_annot = {}
    main_gff = dict()
    header = []
    fasta = []
    fasta_flag = False
    with open(in_gff, "r") as f:
        for line in f:
            line = line.strip()
            if line[0] != "#" and not fasta_flag:
                line = line.replace("db_xref", "Dbxref")
                cols = line.split("\t")
                if len(cols) == 9:
                    contig, caller, feature, start, annot = cols[0], cols[1], cols[2], cols[3], cols[8]
                    if feature != "CDS":
                        if caller == "Bakta" and feature == "region":
                            main_gff.setdefault(contig, dict()).setdefault(int(start), list()).append(line)
                            continue
                        else:
                            continue
                    protein = annot.split(";")[0].split("=")[-1]
                    added_annot[protein] = {}
                    try:
                        eggnogs[protein]
                        pos = 0
                        for a in eggnogs[protein]:
                            pos += 1
                            if a != [""] and a != ["NA"]:
                                if pos == 1:
                                    added_annot[protein]["eggNOG"] = a
                                elif pos == 2:
                                    added_annot[protein]["cog"] = a
                                elif pos == 3:
                                    added_annot[protein]["kegg"] = a
                                elif pos == 4:
                                    added_annot[protein]["Ontology_term"] = a
                    except KeyError:
                        pass
                    try:
                        iprs[protein]
                        pos = 0
                        for a in iprs[protein]:
                            pos += 1
                            a = list(a)
                            if a != [""] and a:
                                if pos == 1:
                                    added_annot[protein]["pfam"] = sorted(a)
                                elif pos == 2:
                                    added_annot[protein]["interpro"] = sorted(a)
                    except KeyError:
                        pass
                    try:
                        dbcan_annotations[protein]
                        added_annot[protein]["dbCAN"] = dbcan_annotations[protein]
                    except KeyError:
                        pass
                    for a in added_annot[protein]:
                        value = added_annot[protein][a]
                        if type(value) is list:
                            value = ",".join(value)
                        if a in ["dbCAN"]:
                            cols[8] = "{};{}".format(cols[8], value)
                        else:
                            if not value == "-":
                                cols[8] = "{};{}={}".format(cols[8], a, value)
                    line = "\t".join(cols)
                    main_gff.setdefault(contig, dict()).setdefault(
                        int(start), list()
                    ).append(line)
            elif line.startswith("#"):
                if line == "##FASTA":
                    fasta_flag = True
                    fasta.append(line)
                else:
                    header.append(line)
            elif fasta_flag:
                fasta.append(line)
    return header, main_gff, fasta

def parse_args():
    parser = argparse.ArgumentParser(
        description="Add functional annotation to GFF file",
    )
    parser.add_argument(
        "-g",
        dest="gff_input",
        required=True,
        help="GFF input file",
    )
    parser.add_argument(
        "-i",
        dest="ips",
        help="InterproScan annotations results for the cluster rep",
        required=False,
    )
    parser.add_argument(
        "-e",
        dest="eggnog",
        help="eggnog annotations for the cluster repo",
        required=True,
    )
    parser.add_argument(
        "--dbcan",
        help="The GFF file produced by dbCAN post-processing script",
        required=False,
    )
    parser.add_argument("-o", dest="outfile", help="Outfile name", required=True)

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    main(
        args.gff_input,
        args.ips,
        args.eggnog,
        args.dbcan,
        args.outfile,
    )
