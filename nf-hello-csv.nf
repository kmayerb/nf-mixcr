// including --aws flag will turn this to true 
params.aws = false

if(params.aws) { 
   params.index = "$baseDir/manifest-aws.txt"
} else { 
   params.index = "$baseDir/manifest.txt"
}                 


if(params.aws) { 
   params.pubdir = "s3://fh-pi-gilbert-p/nextflow_results/hello"
} else { 
   params.pubdir = "output" 
}


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