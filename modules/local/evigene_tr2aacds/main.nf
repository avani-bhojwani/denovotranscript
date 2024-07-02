process EVIGENE_TR2AACDS {
    tag "$meta.id"
    label 'process_medium'
    // code from https://github.com/nf-core/modules/pull/5898 (awaiting review and merge)
    conda "bioconda::evigene=23.7.15"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/evigene:23.7.15--hdfd78af_1':
        'biocontainers/evigene:23.7.15--hdfd78af_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("dropset")    , emit: dropset
    tuple val(meta), path("okayset")    , emit: okayset
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args     ?: ''
    def prefix      = task.ext.prefix   ?: "${meta.id}"

    def max_memory  = 7*1024
    if (!task.memory) {
        log.info '[evigene] Available memory not known - defaulting to 7GB. Specify process memory requirements to change this.'
    } else {
        max_memory  = (task.memory.mega*0.8).intValue()
    }

    def simple_name = fasta.simpleName
    def rename_files= ( simple_name != prefix ) ? 'yes' : 'no'
    """
    # Nextflow changes the container --entrypoint to /bin/bash (container default entrypoint: /usr/local/env-execute)
    # Check for container variable initialisation script and source it.
    if [ -f "/usr/local/env-activate.sh" ]; then
        set +u  # Otherwise, errors out because of various unbound variables
        . "/usr/local/env-activate.sh"
        set -u
    fi

    \$EVIGENEHOME/scripts/prot/tr2aacds.pl \\
        $args \\
        -NCPU=$task.cpus \\
        -MAXMEM=$max_memory \\
        -cdnaseq $fasta

    find \\
        dropset \\
        -type f \\
        -exec sh -c 'mv "\$1" "\$(echo \$1 | sed s/$simple_name/$prefix/)"' sh {} \\;

    find \\
        okayset \\
        -type f \\
        -exec sh -c 'mv "\$1" "\$(echo \$1 | sed s/$simple_name/$prefix/)"' sh {} \\;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tr2aacds: \$(cat \$EVIGENEHOME/scripts/prot/tr2aacds.pl | sed -n 's/use constant VERSION =>  \\([^;]*\\);.*/\\1/p')
    END_VERSIONS
    """
}
