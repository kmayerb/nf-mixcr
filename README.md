# nf-mixcr

Documenting the Creation of a Nextflow Pipeline For MiXCR (TCR Features From Bulk fastq Files)

## Process 1 

### Background 

MiXCR is : "MiXCR is a universal framework that processes big immunome data from raw sequences to quantitated clonotypes."

* excellent documentation: https://mixcr.readthedocs.io/en/master/index.html
* active official docker repo:  https://hub.docker.com/r/milaboratory/mixcr


### Get Test Files

Zenodo file archive (October 24, 2019) : https://zenodo.org/record/3518366#.XbobYS2ZNC0

### Test With Docker

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


## Basic Nextflow Script





### New to Nexflow: Something Really Basic Script

Here is a really basic nextflow script. It takes a list of files.

It Capatalizes and emphasizes the letter "R"


```
It opens a channel of filenames from manifest.txt, passing
file names to (meta.py), which reads the file line by line,
performing conversion to uppercase letters.

```python
import sys

fh = open(sys.argv[1], "r")

for line in fh:
	sys.stdout.write(line.strip().upper() + "\n")

fh.close()
```

The stdout result is passes through a channel to (remove_r.py), which
does the fancy business with the letter "R" converting it to "_r_": 

```python
import sys

fh = open(sys.argv[1], "r")

for line in fh:
	sys.stdout.write(line.strip().replace("R","_r_") + "\n")

fh.close()

```

for test1.txt:

```bash
ardvark
antelope
```
Becomes

```bash
A_r_DVA_r_K
ANTELOPE
```
for test2.txt:

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









