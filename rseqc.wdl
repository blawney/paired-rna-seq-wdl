workflow test_rseqc{

    File input_bam
    File input_bam_index
    String genome

    call infer_experiment {
        input:
            input_bam = input_bam,
            input_bam_index = input_bam_index,
            genome = genome
    }

    output {
        File infer_experiment_result = infer_experiment.infer_results
    }

}

task infer_experiment {

    File input_bam
    File input_bam_index
    String genome

    Int disk_size = 100
    Int reads_sampled = 200000
    String outfile_name = "infer_experiment_output.csv"
    Map[String, File] annotation_bed_map = {
        "Ensembl Homo sapiens GRCh38.95":"gs://cnap-hsph-resources/grch38.95/grch38.95.bed12_annotations.bed",
        "Ensembl Mus musculus GRCm38.95":"gs://cnap-hsph-resources/grcm38.95/grcm38.95.bed12_annotations.bed"
    }

    command {
        alternate_infer_experiment.py \
           -i ${input_bam} \
           -r ${annotation_bed_map[genome]} \
           -s ${reads_sampled} \
           -o ${outfile_name}
    }

    output {
        File infer_results = "${outfile_name}"
    }

    runtime {
        docker: "docker.io/blawney/rnaseq:v0.0.1"
        cpu: 2
        memory: "8 G"
        disks: "local-disk " + disk_size + " HDD"
        preemptible: 0
    }
}

task qc_process {

    File input_bam
    File input_bam_index
    String genome

    Int disk_size = 100

    command {
        echo "QC" > "qc_output.txt"
    }

    output {
        File qc_output = "qc_output.txt"
    }

    runtime {
        docker: "docker.io/blawney/rnaseq:v0.0.1"
        cpu: 2
        memory: "8 G"
        disks: "local-disk " + disk_size + " HDD"
        preemptible: 0
    }
}