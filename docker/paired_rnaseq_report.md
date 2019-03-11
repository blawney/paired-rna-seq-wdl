## Report for paired RNA-Seq analysis


This document discusses the steps that were performed in the analysis pipeline.  It also describes the format of the output files and some brief interpretation.  For more detailed questions about interpretation of results, consult the documentation of the various tools.


#### Version control:
To facilitate reproducible analyses, the analysis pipeline used to process the data is kept under git-based version control.  The repository for this workflow is at 

<{{git_repo}}>

and the commit version was {{git_commit}}.

This allows us to run the *exact* same pipeline at any later time, discarding any updates or changes in the process that may have been added.  


#### Methods:

Input fastq-format files are aligned to the {{genome}} reference genome using the STAR aligner ({{star_version}}) [1].  BAM-format alignment files were filtered to retain only the primary-aligned reads using samtools ({{samtools_version}}) [3].  Additionally, "de-duplicated" versions of the primary-filtered BAM files were created using PicardTools' MarkDuplicates software ({{picard_mark_duplicates_version}})[4].  Both BAM files were indexed and quantified using featureCounts software ({{featurecounts_version}})[2] where counts were generated with respect to exon features.  Integer counts were concatenated into a file count "matrix" with rows denoting genes and samples denoting the samples.

Quality-control software included FastQC ({{fastqc_version}}), RSeQC ({{rseqc_version}}), and MultiQC ({{multiqc_version}}).  Please see the respective references for interpretation of output information and figures.

Note that we provide both the "unfiltered" and the "deduplicated" BAM files.  Depending on the quality of the experiment (e.g. very low input requiring many PCR cycles), it might makes sense to use the "deduplicated" version to reduce potential biases introduced by high-duplication rates.

#### Inputs:
The inputs to the workflow were given as:

Samples and sequencing fastq-format files:
{% for obj in file_display %}
  - {{obj.sample_name}}
    - R1 fastq: {{obj.r1}}
    - R2 fastq: {{obj.r2}}
{% endfor %}

#### Outputs:

The final output consists of various directories, including:
- QC
  - This directory contains an interactive HTML-based QC report which summarizes read quality, alignment quality, and other metrics.  It was produced by MultiQC, and information can be found at <https://multiqc.info/>.
  - Other QC plots are provided, produced by the RSeQC tool.  See documentation at <http://rseqc.sourceforge.net/> for details on each plot.
- Alignments
  - Alignment files in BAM format, and their corresponding index files for use with programs such as `IGV`.
- Quantifications
  - Quantification tables, which give the number of reads aligned to each gene.  Files are tab-delimited.  These may be opened with your software of choice, including spreadsheet software such as Excel (note: <https://doi.org/10.1186/s13059-016-1044-7>).  For particulars on how this achieved, please see the featureCounts documentation or publication
- Logs
  - This contains logs and summaries produced by the various tools.  These can be used for troubleshooting, if necessary.

#### References:

[1] Dobin A. et al. STAR: ultrafast universal RNA-seq aligner.  Bioinformatics. 2013.
[2] Liao Y. and  Smyth G.K. and Shi W. featureCounts: an efficient general purpose program for assigning sequence reads to genomic features.  Bioinformatics. 2014
[3] Li H. and Handsaker B. and Wysoker A. and Fennell T. and Ruan J. and Homer N. and Marth G. and Abecasis G. and Durbin R. and 1000 Genome Project Data Processing Subgroup.  The Sequence alignment/map (SAM) format and SAMtools.  Bioinformatics. 2009.
[4] <http://broadinstitute.github.io/picard/>
