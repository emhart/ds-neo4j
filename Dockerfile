# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM jupyter/scipy-notebook
FROM java:openjdk-8-jre


MAINTAINER Jupyter Project <jupyter@googlegroups.com>

USER root

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc && apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# Julia dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    julia \
    libnettle4 && apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

USER emhart

# R packages including IRKernel which gets installed globally.
RUN conda config --add channels r && \
    conda install --quiet --yes \
    'rpy2=2.7*' \
    'r-base=3.2*' \
    'r-irkernel=0.5*' \
    'r-plyr=1.8*' \
    'r-devtools=1.9*' \
    'r-dplyr=0.4*' \
    'r-ggplot2=1.0*' \
    'r-tidyr=0.3*' \
    'r-shiny=0.12*' \
    'r-rmarkdown=0.8*' \
    'r-forecast=5.8*' \
    'r-stringr=0.6*' \
    'r-rsqlite=1.0*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.1*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-RNeo4j=1.*' \
    'Py2neo' \
    'r-randomforest=4.6*' && conda clean -tipsy

# Install IJulia packages as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
RUN julia -e 'Pkg.add("IJulia")' && \
    mv /home/$NB_USER/.local/share/jupyter/kernels/* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf /home/$NB_USER/.local/share

# Show Julia where conda libraries are
# Add essential packages
RUN echo 'push!(Sys.DL_LOAD_PATH, "/opt/conda/lib")' > /home/$NB_USER/.juliarc.jl && \
    julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")' && julia -F -e 'Pkg.add("HDF5")'

USER root


    ENV NEO4J_VERSION 3.0.0
    ENV NEO4J_EDITION community
    ENV NEO4J_DOWNLOAD_SHA256 1f1aeb3c748d5b05c263b7dab8b195df788507f59228e80534ed8e506a80c517
    ENV NEO4J_DOWNLOAD_ROOT http://dist.neo4j.org
    ENV NEO4J_TARBALL neo4j-$NEO4J_EDITION-$NEO4J_VERSION-unix.tar.gz
    ENV NEO4J_URI $NEO4J_DOWNLOAD_ROOT/$NEO4J_TARBALL



RUN curl --fail --silent --show-error --location --output neo4j.tar.gz $NEO4J_URI \
        && echo "$NEO4J_DOWNLOAD_SHA256 neo4j.tar.gz" | sha256sum --check --quiet - \
        && tar --extract --file neo4j.tar.gz --directory /var/lib \
        && mv /var/lib/neo4j-* /var/lib/neo4j \
        && rm neo4j.tar.gz

WORKDIR /var/lib/neo4j

RUN mv data /data \
        && ln --symbolic /data

VOLUME /data

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 7474 7473 7687

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
