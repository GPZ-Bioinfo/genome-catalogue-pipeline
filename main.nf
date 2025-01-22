#!/usr/bin/env nextflow

include {CREATE_CATALOGUE} from './workflows/create_catalogue'

workflow {
    CREATE_CATALOGUE()
}