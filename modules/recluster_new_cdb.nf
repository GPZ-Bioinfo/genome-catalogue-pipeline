process GET_NEW_CDB {

    
    container 'quay.io/microbiome-informatics/genomes-pipeline.python3base:v1.1'

    input:
    path catalog_cdb_csv
    path recluster_cdb_csv
    
    output:
    
    path "new_cdb.csv", emit:  new_cdb_csv

    script:
    """
    recluster_new_cdb.py -old ${catalog_cdb_csv} -new ${recluster_cdb_csv} -o new_cdb.csv
    """
}