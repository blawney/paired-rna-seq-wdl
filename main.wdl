import "single_sample_rnaseq.wdl" as single_sample_rnaseq
import "feature_counts.wdl" as feature_counts
import "multiqc.wdl" as multiqc
import "fastqc.wdl" as fastqc


workflow PairedRnaSeqWorkflow{
    # This workflow is a 'super' workflow that parallelizes
    # RNA-seq analysis over multiple samples

    Array[File] r1_files
    Array[File] r2_files
    String genome
    String output_tar_name

    Array[Pair[File, File]] fastq_pairs = zip(r1_files, r2_files)
    scatter(item in fastq_pairs){

        call fastqc.run_fastqc as fastqc_for_read1 {
            input:
                fastq = item.left
        }

        call fastqc.run_fastqc as fastqc_for_read2 {
            input:
                fastq = item.right
        }

        call single_sample_rnaseq.SingleSampleRnaSeqWorkflow as single_sample_process{
            input:
                r1_fastq = item.left,
                r2_fastq = item.right,
                genome = genome
        }
    }

    call feature_counts.concatenate as merge_primary_counts {
        input:
            count_files = single_sample_process.primary_filter_feature_counts_file,
            output_filename = "raw_primary_counts.tsv"
    }

    call feature_counts.concatenate as merge_dedup_counts {
        input:
            count_files = single_sample_process.dedup_feature_counts_file,
            output_filename = "raw_primary_and_deduplicated_counts.tsv"
    }

    call multiqc.create_qc as experimental_qc {
        input:
            star_logs = single_sample_process.star_log,
            fc_logs = single_sample_process.primary_filter_feature_counts_summary,
            r1_fastqc_zips = fastqc_for_read1.fastqc_zip,
            dedup_metrics = single_sample_process.dedup_metrics,
            r2_fastqc_zips = fastqc_for_read2.fastqc_zip
    }

    call tar_results {
        input:
            tar_name = output_tar_name,
            primary_fc_file = merge_primary_counts.count_matrix,
            dedup_fc_file = merge_dedup_counts.count_matrix,
            primary_bam_files = single_sample_process.primary_bam,
            primary_bam_index_files = single_sample_process.primary_bam_index,
            star_logs = single_sample_process.star_log,
            dedup_fc_summaries = single_sample_process.dedup_feature_counts_summary, 
            primary_fc_summaries = single_sample_process.primary_filter_feature_counts_summary,
            dedup_metrics = single_sample_process.dedup_metrics,
            multiqc_report = experimental_qc.report
    }

    output {
        File tar_out = tar_results.tar_out
    }

    meta {
        workflow_title : "Paired-end RNA-Seq quantification"
        workflow_short_description : "For quantifying RNA-seq reads from paired-end protocol"
        workflow_long_description : "Use this workflow for quantifying paired-end RNA-seq expression data into a single expression matrix."
    }
}

task tar_results {

    String tar_name 

    File primary_fc_file
    File dedup_fc_file
    Array[File] primary_bam_files
    Array[File] primary_bam_index_files
    Array[File] star_logs
    Array[File] dedup_fc_summaries 
    Array[File] primary_fc_summaries
    Array[File] dedup_metrics
    File multiqc_report

    command {
        tar -cf "${tar_name}.tar" \
            ${primary_fc_file} \
            ${dedup_fc_file} \
            ${multiqc_report} \
            ${sep=" " primary_bam_files} \
            ${sep=" " primary_bam_index_files} \
            ${sep=" " star_logs} \
            ${sep=" " dedup_fc_summaries} \
            ${sep=" " primary_fc_summaries} \
            ${sep=" " dedup_metrics}
    }

    output {
        File tar_out = "${tar_name}.tar"
    }
}
