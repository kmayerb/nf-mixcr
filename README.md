[![Build Status](https://travis-ci.com/kmayerb/nf-mixcr.svg?branch=master)](https://travis-ci.com/kmayerb/nf-mixcr)

# nf-mixcr

Documenting the Creation of a Nextflow Pipeline For MiXCR (TCR Features From Bulk fastq Files)

## Background 

MiXCR is : "MiXCR is a universal framework that processes big immunome data from raw sequences to quantitated clonotypes."

* excellent documentation: https://mixcr.readthedocs.io/en/master/index.html
* active official docker repo:  https://hub.docker.com/r/milaboratory/mixcr

### Get Test Files

Zenodo file archive (October 24, 2019) : https://zenodo.org/record/3518366#.XbobYS2ZNC0

### Test With 

#### Dockerfile

```Docker
FROM openjdk:11

ARG version="3.0.11"

RUN mkdir /work

RUN cd / \
    && wget -q https://github.com/milaboratory/mixcr/releases/download/v${version}/mixcr-${version}.zip \
    && unzip mixcr-${version}.zip \
    && mv mixcr-${version} mixcr \
    && rm mixcr-${version}.zip

ENV PATH="/mixcr:${PATH}"

WORKDIR /work

ENTRYPOINT ["/bin/bash"]
```
Sam Minot advised that ENTRYPOINTS spell trouble for containers in nextflow. The official docker file may need to be modified to remove the ENTRYPOINT.


#### Pull Docker Image
```
>>> docker pull milaboratory/mixcr:3-imgt
```

#### Run Interactive Docker Container
```
>>> docker run -v ${HOME}/docker-mixcr:/work -it milaboratory/mixcr:3-imgt
root@d7963bb03de7:/work# mixcr align test_R1.fastq test_R2.fastq test2.vdjca --species hsa
root@d7963bb03de7:/work# mixcr assemble test2.vdjca output.clns
root@d7963bb03de7:/work# mixcr exportClones output.clns output.clns.txt
root@d7963bb03de7:/work# mixcr exportAlignments test2.vdjca test2.vdjca.txt
```

The following commands produce output files: test2.vdjca.txt and output.clns.txt

```
mixcr align test_R1.fastq test_R2.fastq test2.vdjca --species hsa
mixcr assemble test2.vdjca output.clns
mixcr exportClones output.clns output.clns.txt
mixcr exportAlignments test2.vdjca test2.vdjca.txt
```

This is a process that can be encapsulated into a workflow.


# Nextflow

## Basic Nextflow Script Talking to This Container

Here is my attempt to write a nextflow pipeline that uses a containerized tool.
I had to try a number of things, and finally only the nuclear option:
`-with-docker 'milaboratory/mixcr:3-imgt'`
got my workflow to recognize and use the container.

#### execution
```bash
>>> nextflow nf-mixcr.nf -with-docker 'milaboratory/mixcr:3-imgt'
N E X T F L O W  ~  version 19.07.0
Launching `nf-mixcr.nf` [irreverent_mcnulty] - revision: 5fe772c3ce
executor >  local (4)
[c6/3b6962] process > align (1)      [100%] 2 of 2 ✔
[7b/dd231c] process > cut_fields (2) [100%] 2 of 2 ✔
```
#### nextflow.config:
```
process.executor = 'local'

process.container = 'milaboratory/mixcr:3-imgt'

docker {
    enabled = true
    temp = 'auto'
}
```

#### script
```nextflow
// sets global params
params.output_folder = "./output" 
params.input_folder = 'input_folder'

// Q1 - This is a really rigid way of reading paired end read files
// See the section below for a Question 1 about how to do this more elegantly
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
```
#### Many Hours Later configuring the nextflow Cocoon, the FastaQ becomes a Butterfly.

A humble pair of FASTQ, 
```
@R1_0
ATGAGCATCAGCCTCCTGTGCTGTGCAGCCTTTCCTCTCCTGTGGGCAGGTCCAGTGAATGCTGGTGTCACTCAGACCCCAAAATTCCGCATCCTGAAGATAGGACAGAGCATGACACTGCAAGTTACCCAGGATAGAACCATGAATACA
+
JKC<C?JHHJ?DKIA/BIKHAGA7K<C<>JKDHFHKBGHAHKH:DHF@@CDAJGEGEFGHFCFGGI5CKFKIF;GBKEEADJGJH:DFJHHDC;:JKC=IJJ:<FAEIJGHKCEKC6F5>ICA7GK=IFJKBI=K>;BBHIHJIJ><HGB
@R1_1
...
```
, becomes a flat file:

```
allVHitsWithScore	allJHitsWithScore	nSeqCDR3	aaSeqCDR3
TRBV6-4*00(816)	TRBJ1-3*00(187)	TGTGCCAGCATTGACTACATGGAAACACCATATATTTT	CASIDY_GNTIYF
TRBV9*00(791)	TRBJ2-3*00(233)	TGTGCCAGCAGCGTAAGCACAGATACGCAGTATTTT	CASSVSTDTQYF
...
```


### New to Nexflow: A Fun Basic Script


```nextflow
params.manifest = "manifest.txt"  
params.output_folder = "./output" 


fastq_ch = Channel.from(file(params.manifest).readLines())
                  .map {it -> file(it)}

process meta {
    /* 
     * publishDir params.output_folder
     */

    input:
    file input_fastq from fastq_ch
    
    output:
    file "${input_fastq}.meta.tsv" into result

    """
    python /Users/kmayerbl/gitrepo/nf-example/meta.py ${input_fastq} > ${input_fastq}.meta.tsv
    """
}

process remove_r {
    publishDir params.output_folder

    input:
    file uppercase_fastq from result
    
    output:
    file "${uppercase_fastq}.remove_r.tsv" 

    """
    python /Users/kmayerbl/gitrepo/nf-example/remove_r.py ${uppercase_fastq} > "${uppercase_fastq}.remove_r.tsv" 
    """    

}
```


Here is a really basic nextflow script. It takes a list of files.
It Capatalizes and emphasizes the letter "R". 
It does this for many files, by openning a channel containing 
filenames from manifest.txt, passing file names to (meta.py):

```python
import sys

fh = open(sys.argv[1], "r")

for line in fh:
	sys.stdout.write(line.strip().upper() + "\n")

fh.close()
```

From which, the stdout result is passes through a channel to (remove_r.py), which does the fancy business with the letter "R" converting it to "_r_": 

```python
import sys

fh = open(sys.argv[1], "r")

for line in fh:
	sys.stdout.write(line.strip().replace("R","_r_") + "\n")

fh.close()

```

So, test1.txt:

```bash
ardvark
antelope
```
Becomes:

```bash
A_r_DVA_r_K
ANTELOPE
```
And, test2.txt:

```bash
bat
beaver
bear
```
Becomes
```bash
BAT
BEAVE_r_
BEA_r_
```








