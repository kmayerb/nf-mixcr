// sets global params
params.output_folder = "./output" 
params.input_folder = 'input_folder'

// Q1 - This is a really rigid way of reading paired end read files
// That relies on all files being in a folder and being named conventionally
// i.e., SampleID_R1.fq, SampleID_R2.fq 
// See the section below for a Question 1 about how to do this more
// elegantly
fastq_pair_ch = Channel.fromFilePairs(params.input_folder + '/*_R{1,2}.fq', flat:true)


process align {

    /* Process 1:
     * Paired-end read fastq files are aligned to IMGT TCRs and flat files
     * are exported containing v,j gene usage and cdr3a and cdr3nuc
     * and many other fields
     * 
     * Inputs : 
     * 
     * Returns :
     */

  
    // Q2 - See Below for Question 2

	container 'milaboratory/mixcr:3-imgt'
	
	publishDir params.output_folder

	input:
    set pair_name, file(fastq1), file(fastq2) from fastq_pair_ch

    output:  
    file "${pair_name}.result.txt" into align_result_channel

    """
    mixcr align ${fastq1} ${fastq2} test2.vdjca --species hsa
    mixcr assemble test2.vdjca output.clns
    mixcr exportClones output.clns output.clns.txt
    mixcr exportAlignments test2.vdjca ${pair_name}.result.txt
    """

}

process cut_fields{

    /* Process 2
     * Cuts MiXCR exported alignments at tabs returns field 3,5,21,30
     * 3: v gene
     * 5: j gene 
     * 21: cdr3_nucleotide
     * 30 : cdr3_amino_acid
     * 
     * Inputs :
     * 
     * Returns :
     */

    container 'milaboratory/mixcr:3-imgt'
    
    publishDir params.output_folder

    input:
    set file(res) from align_result_channel

    output:
    file "${res}.v_j_cdr3_n_cdr3_aa.txt" into final_results

    """
    more "${res}" | cut -d'\t' -f3,5,21,30 > ${res}.v_j_cdr3_n_cdr3_aa.txt
    """
}


/* QUESTIONS FOR SAM AND THE NEXTFLOW GROUP
 * Q1: How can I elegantly get filenames from a columns of a manifest.csv file
 *  
 * I tried the following, but was unsuccessful. Is there a good template for this?
 *
 * Channel
 *   .fromPath(params.index)
 *   .splitCsv(header:true)
 *   .map{ row-> tuple(row.pair_name, file(row.fastq1), file(row.fastq2)) }
 *   .set { fastq_pair_ch }
 */


/*
 * Q2: container 'milaboratory/mixcr:3-imgt' was not sufficient to make 
 * nextflow use this docker container
 * I had to manually use the flag -with-docker 'milaboratory/mixcr:3-imgt'
 * 
 * Could we look at my config file to see why the container command below is 
 * not sufficient to trigger containerization
 * 
 * My nextflow.config:
 *
 * process.executor = 'local'
 * process.container = 'milaboratory/mixcr:3-imgt'
 * docker {
 *  enabled = true
 *  temp = 'auto'
 * }
 *
 * Q3: Can we have a config in this working folder rather than ${HOME}/nextflow.config 
 */