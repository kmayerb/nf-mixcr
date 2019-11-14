// --aws
params.aws = false

//
params.index = ( params.aws
                 ? [ "$baseDir/manifest-aws.txt" ]
                 : [ "$baseDir/manifest.txt" ] )

//
params.pubdir = ( params.aws
                 ? [ "s3://fh-pi-gilbert-p/nextflow_results/hello"]
                 : [ "output" ] )



Channel
    .fromPath(params.index)
    .splitCsv(header:true)
    .map{ row-> tuple(row.sampleId, file(row.read1), file(row.read2)) }
    .set { samples_ch }


process hello {

    // a container images is required
    container "milaboratory/mixcr:3-imgt"

    // compute resources for the Batch Job
    cpus 1
    memory '512 MB'

    input:
    set sampleId, file(read1), file(read2) from samples_ch

    output:
    file "${sampleId}.hello.txt"

    // were to send the output
    //publishDir 
    publishDir params.pubdir
    """
    echo $sampleId >> ${sampleId}.hello.txt
    echo $read1 >> ${sampleId}.hello.txt
    echo $read2 >> ${sampleId}.hello.txt
    """
}