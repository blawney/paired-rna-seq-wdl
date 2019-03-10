#!/usr/bin/python3

import subprocess as sp
import argparse
import sys
import os
from jinja2 import Environment, FileSystemLoader

# some variables for common reference.  Their actual values are tied to the 
# template we are filling
R1 = 'r1_files'
R2 = 'r2_files'
GENOME = 'genome'
TEMPLATE = 'template'
OUTPUT = 'output'
GIT_REPO = 'git_repo'
GIT_COMMIT = 'git_commit'


def get_jinja_template(template_path):
    '''
    Returns a jinja template to be filled-in
    '''
    template_dir = os.path.dirname(template_path)
    env = Environment(loader=FileSystemLoader(template_dir))
    return env.get_template(
        os.path.basename(template_path)
    )


def run_cmd(cmd, return_stderr=False):
    '''
    Runs a command through the shell
    '''
    p = sp.Popen(cmd, shell=True, stderr=sp.PIPE, stdout=sp.PIPE)
    stdout, stderr = p.communicate()
    if return_stderr:
        return stderr.decode('utf-8')
    return stdout.decode('utf-8')


def get_versions():
    '''
    Runs the command to get the versions
    '''
    star_version_str = run_cmd('STAR --version')
    samtools_version_str = run_cmd('samtools --version')
    fc_version_str = run_cmd('featureCounts -v', return_stderr=True)
    multiqc_version_str = run_cmd('multiqc --version')
    fastqc_version_str = run_cmd('fastqc --version')
    rseqc_version_str = run_cmd('pip3 freeze | grep RSeQC')
    picard_md_str = run_cmd('java -jar /opt/software/picard/picard.jar MarkDuplicates --version', return_stderr=True)
    
    # post-process these to extract just the version number:
    star_version = star_version_str.strip().split('_')[1]
    samtools_version = samtools_version_str.split('\n')[0].split(' ')[1]
    fc_version = fc_version_str.strip().split(' ')[-1]
    multiqc_version = multiqc_version_str.strip().split(',')[-1].split(' ')[-1]
    fastqc_version = fastqc_version_str.strip().split(" ")[-1]
    rseqc_version = rseqc_version_str.strip().split('==')[1]
    picard_md_version = picard_md_str.strip()

    d = {}
    d['star_version'] = star_version
    d['samtools_version'] = samtools_version
    d['featurecounts_version'] = fc_version
    d['multiqc_version'] = multiqc_version
    d['fastqc_version'] = fastqc_version
    d['rseqc_version'] = rseqc_version
    d['picard_mark_duplicates_version'] = picard_md_version
    return d


def parse_input():
    '''
    Parses the commandline input, returns a dict
    '''
    parser = argparse.ArgumentParser()
    parser.add_argument('-r1', required=True, dest=R1, nargs='+')
    parser.add_argument('-r2', required=True, dest=R2, nargs='+')
    parser.add_argument('-g', required=True, dest=GENOME)
    parser.add_argument('-t', required=True, dest=TEMPLATE)
    parser.add_argument('-o', required=True, dest=OUTPUT)
    parser.add_argument('-r', required=True, dest=GIT_REPO)
    parser.add_argument('-c', required=True, dest=GIT_COMMIT)
    args = parser.parse_args()
    return vars(args)


def fill_template(context, template_path, output):
    if os.path.isfile(template_path):
        template = get_jinja_template(template_path)
        with open(output, 'w') as fout:
            fout.write(template.render(context))
    else:
        print('The report template was not valid: %s' % template_path)
        sys.exit(1)


if __name__ == '__main__':

    # parse commandline args and separate the in/output from the
    # context variables
    arg_dict = parse_input()
    output_file = arg_dict.pop(OUTPUT)
    input_template_path = arg_dict.pop(TEMPLATE)

    # get all the software versions:
    versions_dict = get_versions()

    # alter how the files are displayed:
    r1_files = arg_dict[R1]
    r2_files = arg_dict[R2]
    samples = [os.path.basename(x)[:-len('_R1.fastq.gz')] for x in r1_files]
    file_display = []
    for r1, r2, s in zip(r1_files, r2_files, samples):
        file_display.append('**%s**: %s, %s' % (s, r1, r2))
    
    # make the context dictionary
    context = {}
    context.update(versions_dict)
    context.update(arg_dict)
    context.update({'file_display': file_display})

    # fill and write the completed report:
    fill_template(context, input_template_path, output_file)
