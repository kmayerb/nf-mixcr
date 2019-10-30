# nf-mixcr


## Process 1 

MiXCR is : "MiXCR is a universal framework that processes big immunome data from raw sequences to quantitated clonotypes."

* It has excellent documentation: https://mixcr.readthedocs.io/en/master/index.html

* It has an active offial docker repo:  https://hub.docker.com/r/milaboratory/mixcr


### Get test files

Use files in Zenodo file archive (October 24, 2019) : https://zenodo.org/record/3518366#.XbobYS2ZNC0

### test with docker


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






