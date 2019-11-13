texts = Channel.from("AWS", "Nextflow")

process hello {
    // directives
    // a container images is required
    container "milaboratory/mixcr:3-imgt"

    // compute resources for the Batch Job
    cpus 1
    memory '512 MB'

    input:
    val text from texts

    output:
    file 'hello.txt'
    publishDir "s3://fh-pi-gilbert-p/nextflow_results/hello"

    """
    echo "Hello $text" > hello.txt
    """
}