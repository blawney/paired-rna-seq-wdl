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
    File star_index_path
    File gtf
    File bed_annotations
    String output_zip_name
    String git_repo_url
    String git_commit_hash

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
                star_index_path = star_index_path,
                gtf = gtf,
                bed_annotations = bed_annotations
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

    call generate_report {
        input:
            r1_files = r1_files,
            r2_files = r2_files,
            genome = genome,
            git_commit_hash = git_commit_hash,
            git_repo_url = git_repo_url
    }

    call zip_results {
        input:
            zip_name = output_zip_name,
            primary_fc_file = merge_primary_counts.count_matrix,
            dedup_fc_file = merge_dedup_counts.count_matrix,
            primary_bam_files = single_sample_process.primary_bam,
            primary_bam_index_files = single_sample_process.primary_bam_index,
            star_logs = single_sample_process.star_log,
            dedup_fc_summaries = single_sample_process.dedup_feature_counts_summary, 
            primary_fc_summaries = single_sample_process.primary_filter_feature_counts_summary,
            dedup_metrics = single_sample_process.dedup_metrics,
            multiqc_report = experimental_qc.report,
            analysis_report = generate_report.report
    }

    output {
        File zip_out = zip_results.zip_out
    }

    meta {
        workflow_title : "Paired-end RNA-Seq quantification"
        workflow_short_description : "For quantifying RNA-seq reads from paired-end protocol"
        workflow_long_description : "Use this workflow for quantifying paired-end RNA-seq expression data into a single expression matrix."
    }
}


task generate_report {

    Array[String] r1_files
    Array[String] r2_files
    String genome    
    String git_repo_url
    String git_commit_hash

    Int disk_size = 10

    command <<<
        generate_report.py \
          -r1 ${sep=" " r1_files} \
          -r2 ${sep=" " r2_files} \
          -g "${genome}" \
          -r ${git_repo_url} \
          -c ${git_commit_hash} \
          -t /opt/report/paired_rnaseq_report.md \
          -o completed_report.md

        pandoc -H /opt/report/report.css -s completed_report.md -o analysis_report.html
    >>>

    output {
        File report = "analysis_report.html"
    }

    runtime {
        docker: "docker.io/blawney/rnaseq:v0.0.1"
        cpu: 2
        memory: "2 G"
        disks: "local-disk " + disk_size + " HDD"
        preemptible: 0
    }
}


task zip_results {

    String zip_name 

    File primary_fc_file
    File dedup_fc_file
    Array[File] primary_bam_files
    Array[File] primary_bam_index_files
    Array[File] star_logs
    Array[File] dedup_fc_summaries 
    Array[File] primary_fc_summaries
    Array[File] dedup_metrics
    File multiqc_report
    File analysis_report

    Int disk_size = 500

    command {
        zip -j "${zip_name}.zip" \
            ${primary_fc_file} \
            ${dedup_fc_file} \
            ${multiqc_report} \
            ${analysis_report} \
            ${sep=" " primary_bam_files} \
            ${sep=" " primary_bam_index_files} \
            ${sep=" " star_logs} \
            ${sep=" " dedup_fc_summaries} \
            ${sep=" " primary_fc_summaries} \
            ${sep=" " dedup_metrics}
    }

    output {
        File zip_out = "${zip_name}.zip"
    }

    runtime {
        docker: "docker.io/blawney/rnaseq:v0.0.1"
        cpu: 2
        memory: "6 G"
        disks: "local-disk " + disk_size + " HDD"
        preemptible: 0
    }
}
