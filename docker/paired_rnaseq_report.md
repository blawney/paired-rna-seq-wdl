## Report for paired RNA-Seq analysis


This document discusses the steps that were performed in the analysis pipeline.  It also describes the format of the output files and some brief interpretation.


#### Version control:
To facilitate reproducible analyses, the analysis pipeline used to process the data is kept under git-based version control.  The repository for this workflow is at 

{{git_repo}}

and the commit version was {{git_commit}}.

This allows us to run the *exact* same pipeline at any later time, discarding any updates or changes in the process that may have been added.  


#### Methods:

Input fastq-format files are aligned to the {{genome}} reference genome using the STAR aligner ({{star_version}}).  BAM-format alignment files were filtered to retain only the primary-aligned reads using samtools ({{samtools_version}}).  Additionally, "de-duplicated" versions of the primary-filtered BAM files were created using PicardTools' MarkDuplicates software ({picard_mark_duplicates_version}}).  Both BAM files were indexed and quantified using featureCounts software ({{featurecounts_version}}) where counts were generated with respect to exon features.  Integer counts were concatenated into a file count "matrix" with rows denoting genes and samples denoting the samples.

Quality-control software included FastQC ({{fastqc_version}}), RSeQC ({{rseqc_version}}), and MultiQC ({{multiqc_version}}).  Please see the respective references for interpretation of output information and figures. 

#### Inputs:
The inputs to the workflow were given as:

Samples and sequencing fastq-format files:
{% for i in file_display %}
  - {{i}}
{% endfor %}

#### Outputs:

The final output consists of various files, including:
- An interactive HTML-based QC report which summarizes read quality, alignment quality, and other metrics.
- Alignment files in BAM format, and their corresponding index files for use with programs such as `IGV`.
- Quantification tables, which give the number of reads aligned to each gene.  For particulars on how this achieved, please see .  These may be opened with your software of choice, including spreadsheet software such as Excel (note: https://doi.org/10.1186/s13059-016-1044-7).  Files are tab-delimited if ending with "tsv" or comma-delimited if ending with "csv".

#### References:

References go here

