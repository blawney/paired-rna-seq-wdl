From debian:stretch

RUN apt-get update && \
  apt-get install -y build-essential \
    wget \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libncurses-dev \
    libbz2-dev \
    liblzma-dev \
    zip \
    python3-dev \
    python3-pip \
    default-jre \
    r-base

# Install all software under /opt/software:
RUN mkdir -p /opt/software 

# Install fastQC:
RUN cd /opt/software && \
  wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip && \
  unzip fastqc_v0.11.8.zip && \
  chmod +x /opt/software/FastQC/fastqc
ENV PATH="/opt/software/FastQC:${PATH}"

# Install STAR 2.6:
RUN cd /opt/software && \
  wget https://github.com/alexdobin/STAR/archive/2.6.1d.tar.gz && \
  tar -xzf 2.6.1d.tar.gz && \
  cd STAR-2.6.1d/source && \
  make STAR
ENV PATH="/opt/software/STAR-2.6.1d/bin/Linux_x86_64:${PATH}"

# Install samtools:
RUN cd /opt/software && \
  wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 && \
  tar -xjf samtools-1.9.tar.bz2 && \
  cd samtools-1.9 && \
  ./configure --prefix=/opt/software/samtools && \
  make && \
  make install
ENV PATH="/opt/software/samtools/bin:${PATH}"

# Get the Picard JAR:
RUN mkdir -p /opt/software/picard && \
  cd /opt/software/picard && \
  wget https://github.com/broadinstitute/picard/releases/download/2.18.26/picard.jar
ENV PICARD_JAR=/opt/software/picard/picard.jar

# subRead featureCounts
RUN cd /opt/software && \
  wget https://sourceforge.net/projects/subread/files/subread-1.6.3/subread-1.6.3-source.tar.gz && \
  tar -xzf subread-1.6.3-source.tar.gz && \
  cd subread-1.6.3-source/src && \
  make -f Makefile.Linux
ENV PATH="/opt/software/subread-1.6.3-source/bin:${PATH}"

# Install some scientific Python3 libraries:
RUN pip3 install numpy scipy pandas

# Now install RSeQC:
RUN pip3 install RSeQC

# Install multiqc:
RUN pip3 install multiqc

# for multiqc to read commandline:
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Add other scripts under /usr/local/bin so they are in PATH:
# Script to concatenate the featureCounts output into a matrix:
ADD concatenate_featurecounts.py /usr/local/bin/
RUN chmod +x /usr/local/bin/concatenate_featurecounts.py

# The "alternate" script for inferring the strandedness:
ADD alternate_infer_experiment.py /usr/local/bin/
RUN chmod +x /usr/local/bin/alternate_infer_experiment.py

ENTRYPOINT ["/bin/bash"]
