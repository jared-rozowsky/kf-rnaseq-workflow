# Kids First RNA-Seq Workflow V4

This is the Kids First RNA-Seq pipeline, which calculates gene and transcript isoform expression, detects fusions ans splice junctions.
We are transitioning to to this current version which upgrades several software components.
Our legacy workflow is still available as [v3.0.1](https://github.com/kids-first/kf-rnaseq-workflow/tree/v3.0.1), and on Cavatica, [revision 8](https://cavatica.sbgenomics.com/public/apps/cavatica/apps-publisher/kfdrc-rnaseq-workflow/8)

![data service logo](https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png)

## Introduction
This pipeline has an optional cutadapt to trim adapters from the raw reads, bam-to-fastq conversion if necessary, and passes the reads to STAR for alignment.
The alignment output is used by RSEM for gene expression abundance estimation and rMATS for differential alternative splicing events detection.
Additionally, Kallisto is used for quantification, but uses pseudoalignments to estimate the gene abundance from the raw data.
Fusion calling is performed using Arriba and STAR-Fusion detection tools on the STAR alignment outputs.
Filtering and prioritization of fusion calls is done by annoFuse.
Metrics for the workflow are generated by RNA-SeQC.
Junction files for the workflow are generated by rMATS.

If you would like to run this workflow using the cavatica public app, a basic primer on running public apps can be found [here](https://www.notion.so/d3b/Starting-From-Scratch-Running-Cavatica-af5ebb78c38a4f3190e32e67b4ce12bb).
Alternatively, if you would like to run it locally using `cwltool`, a basic primer on that can be found [here](https://www.notion.so/d3b/Starting-From-Scratch-Running-CWLtool-b8dbbde2dc7742e4aff290b0a878344d) and combined with app-specific info from the readme below.
This workflow is the current production workflow, equivalent to this [Cavatica public app](https://cavatica.sbgenomics.com/public/apps#cavatica/apps-publisher/kfdrc-rnaseq-workflow).

### Cutadapt
[Cutadapt v3.4](https://github.com/marcelm/cutadapt) Cut adapter sequences from raw reads if needed.
### [STAR](docs/STAR_2.7.10a.md) 
[STAR v2.7.10a](https://doi.org/f4h523) RNA-Seq raw data alignment. See 
### [RSEM](docs/RSEM_1.3.1.md)
[RSEM v1.3.1](https://doi:10/cwg8n5) Calculation of gene expression.
### Kallisto
[Kallisto v0.43.1](https://doi:10.1038/nbt.3519) Raw data pseudoalignment to estimate gene abundance.
### [STAR-Fusion](docs/STAR-Fusion_1.10.1.md)
[STAR-Fusion v1.10.1](https://doi:10.1101/120295) Fusion detection for `STAR` chimeric reads.
### [Arriba](docs/ARRIBA_2.2.1.md)
[Arriba v2.2.1](https://github.com/suhrig/arriba/) Fusion caller that uses `STAR` aligned reads and chimeric reads output.
### [annoFuse](docs/D3B_ANNOFUSE.md)
[annoFuse 0.90.0](https://github.com/d3b-center/annoFuse/releases/tag/v0.90.0) Filter and prioritize fusion calls. For more information, please see the following [paper](https://www.biorxiv.org/content/10.1101/839738v3).
### RNA-SeQC
[RNA-SeQC v2.3.4](https://github.com/broadinstitute/rnaseqc) Generate metrics such as gene and transcript counts, sense/antisene mapping, mapping rates, etc
### [rMATS](docs/D3B_RMATS.md)
[rMATS turbo v4.1.2](https://github.com/Xinglab/rmats-turbo) Computational tool to detect differential alternative splicing events from RNA-Seq data

## Usage

### Runtime Estimates:
- 8 GB paired end FASTQ input: 9 hours & $9.00
- 19 GB PE BAM input: 9 hours 30 Minutes & $9.50

### Inputs common:
```yaml
inputs:
  output_basename: { type: 'string', doc: "String to use as basename for outputs" }
  reads1: { type: File, doc: "Input fastq file, gzipped or uncompressed OR bam file" }
  reads2: { type: 'File?', doc: "If paired end, R2 reads files, gzipped or uncompressed" }

  wf_strand_param: { type: [{type: 'enum', name: wf_strand_param, symbols: ["default",
          "rf-stranded", "fr-stranded"]}], doc: "use 'default' for unstranded/auto, 'rf-stranded' if read1 in the fastq read pairs is reverse complement to the transcript, 'fr-stranded' if read1 same sense as transcript" }
  gtf_anno: { type: 'File', doc: "General transfer format (gtf) file with gene models corresponding to fasta reference" }
  star_fusion_genome_untar_path: {type: 'string?', doc: "This is what the path will be when genome_tar is unpackaged", default: "GRCh38_v39_CTAT_lib_Mar242022.CUSTOM"}
  reference_fasta: {type: 'File', doc: "GRCh38.primary_assembly.genome.fa", "sbg:suggestedValue": {
    class: File, path: 5f500135e4b0370371c051b4, name: GRCh38.primary_assembly.genome.fa,
    secondaryFiles: [{class: File, path: 62866da14d85bc2e02ba52db, name: GRCh38.primary_assembly.genome.fa.fai}]},
  secondaryFiles: ['.fai']}

```

### Bam input-specific:
```yaml
inputs:
  reads1: File
```

### PE Fastq input-specific:
```yaml
inputs:
  reads1: File
  reads2: File
```

### SE Fastq input-specific:
```yaml
inputs:
  reads1: File
```

### Samtools fastq:
```yaml
samtools_fastq_cores: { type: 'int?', doc: "Num cores for bam2fastq conversion, if input is bam", default: 16 }
input_type: {type: [{type: 'enum', name: input_type, symbols: ["PEBAM", "SEBAM",
        "FASTQ"]}], doc: "Please select one option for input file type, PEBAM (paired-end BAM), SEBAM (single-end BAM) or FASTQ."}
```
### cutadapt:
```yaml
r1_adapter: { type: 'string?', doc: "Optional input. If the input reads have already been trimmed, leave these as null. If they do need trimming, supply the adapters." }
r2_adapter: { type: 'string?', doc: "Optional input. If the input reads have already been trimmed, leave these as null. If they do need trimming, supply the adapters." }
```
### STAR:
This section may seem overwhelming.
Many defaults are set.
Kids First favors setting/overriding defaults with "arriba-heavy" specified in [STAR docs](docs/STAR_2.7.10a.md), however if it is not a tumor sample, then GTEx is preferred
```yaml
  outSAMattrRGline: {type: string, doc: "Suggested setting, with TABS SEPARATING THE TAGS, format is: ID:sample_name LB:aliquot_id PL:platform SM:BSID for example ID:7316-242 LB:750189 PL:ILLUMINA SM:BS_W72364MN"}
  STARgenome: {type: File, doc: "Tar gzipped reference that will be unzipped at run time", "sbg:suggestedValue": {class: File, path: 62853e7ad63f7c6d8d7ae5a7,
      name: STAR_2.7.10a_GENCODE39.tar.gz}}
  runThreadN: {type: 'int?', default: 16, doc: "Adjust this value to change number of cores used."}
  twopassMode: {type: ['null', {type: enum, name: twopassMode, symbols: ["Basic",
          "None"]}], default: "Basic", doc: "Enable two pass mode to detect novel splice events. Default is basic (on)."}
  alignSJoverhangMin: {type: 'int?', default: 8, doc: "minimum overhang for unannotated junctions. ENCODE default used."}
  outFilterMismatchNoverLmax: {type: 'float?', default: 0.1, doc: "alignment will be output only if its ratio of mismatches to *mapped* length is less than or equal to this value"}
  outFilterType: {type: ['null', {type: enum, name: outFilterType, symbols: ["BySJout",
          "Normal"]}], default: "BySJout", doc: "type of filtering. Normal: standard filtering using only current alignment. BySJout (default): keep only those reads that contain junctions that passed filtering into SJ.out.tab."}
  outFilterScoreMinOverLread: {type: 'float?', default: 0.33, doc: "alignment will be output only if its score is higher than or equal to this value, normalized to read length (sum of mate's lengths for paired-end reads)"}
  outFilterMatchNminOverLread: {type: 'float?', default: 0.33, doc: "alignment will be output only if the number of matched bases is higher than or equal to this value., normalized to the read length (sum of mates' lengths for paired-end reads)"}
  outReadsUnmapped: {type: ['null', {type: enum, name: outReadsUnmapped, symbols: [
          "None", "Fastx"]}], default: "None", doc: "output of unmapped and partially mapped (i.e. mapped only one mate of a paired end read) reads in separate file(s). none (default): no output. Fastx: output in separate fasta/fastq files, Unmapped.out.mate1/2."}
  limitSjdbInsertNsj: {type: 'int?', default: 1200000, doc: "maximum number of junction to be inserted to the genome on the fly at the mapping stage, including those from annotations and those detected in the 1st step of the 2-pass run"}
  outSAMstrandField: {type: ['null', {type: enum, name: outSAMstrandField, symbols: [
          "intronMotif", "None"]}], default: "intronMotif", doc: "Cufflinks-like strand field flag. None: not used. intronMotif (default): strand derived from the intron motif. This option changes the output alignments: reads with inconsistent and/or non-canonical introns are filtered out."}
  outFilterIntronMotifs: {type: ['null', {type: enum, name: outFilterIntronMotifs,
        symbols: ["None", "RemoveNoncanonical", "RemoveNoncanonicalUnannotated"]}],
    default: "None", doc: "filter alignment using their motifs. None (default): no filtering. RemoveNoncanonical: filter out alignments that contain non-canonical junctions RemoveNoncanonicalUnannotated: filter out alignments that contain non-canonical unannotated junctions when using annotated splice junctions database. The annotated non-canonical junctions will be kept."}
  alignSoftClipAtReferenceEnds: {type: ['null', {type: enum, name: alignSoftClipAtReferenceEnds,
        symbols: ["Yes", "No"]}], default: "Yes", doc: "allow the soft-clipping of the alignments past the end of the chromosomes. Yes (default): allow. No: prohibit, useful for compatibility with Cufflinks"}
  quantMode: {type: ['null', {type: enum, name: quantMode, symbols: [TranscriptomeSAM
            GeneCounts, '-', TranscriptomeSAM, GeneCounts]}], default: TranscriptomeSAM
      GeneCounts, doc: "types of quantification requested. -: none. TranscriptomeSAM: output SAM/BAM alignments to transcriptome into a separate file GeneCounts: count reads per gene. Choices are additive, so default is 'TranscriptomeSAM GeneCounts'"}
  outSAMtype: {type: ['null', {type: enum, name: outSAMtype, symbols: ["BAM Unsorted",
          "None", "BAM SortedByCoordinate", "SAM Unsorted", "SAM SortedByCoordinate"]}],
    default: "BAM Unsorted", doc: "type of SAM/BAM output. None: no SAM/BAM output. Otherwise, first word is output type (BAM or SAM), second is sort type (Unsorted or SortedByCoordinate)"}
  outSAMunmapped: {type: ['null', {type: enum, name: outSAMunmapped, symbols: ["Within",
          "None", "Within KeepPairs"]}], default: "Within", doc: "output of unmapped reads in the SAM format. None: no output. Within (default): output unmapped reads within the main SAM file (i.e. Aligned.out.sam) Within KeepPairs: record unmapped mate for each alignment, and, in case of unsorted output, keep it adjacent to its mapped mate. Only affects multi-mapping reads"}
  genomeLoad: {type: ['null', {type: enum, name: genomeLoad, symbols: ["NoSharedMemory",
          "LoadAndKeep", "LoadAndRemove", "LoadAndExit"]}], default: "NoSharedMemory",
    doc: "mode of shared memory usage for the genome file. In this context, the default value makes the most sense, the others are their as a courtesy."}
  chimMainSegmentMultNmax: {type: 'int?', default: 1, doc: "maximum number of multi-alignments for the main chimeric segment. =1 will prohibit multimapping main segments"}
  outSAMattributes: {type: 'string?', default: 'NH HI AS nM NM ch', doc: "a string of desired SAM attributes, in the order desired for the output SAM. Tags can be listed in any combination/order. Please refer to the STAR manual, as there are numerous combinations: https://raw.githubusercontent.com/alexdobin/star_2.7.10a/master/doc/STARmanual.pdf"}
  alignInsertionFlush: {type: ['null', {type: enum, name: alignInsertionFlush, symbols: [
          "None", "Right"]}], default: "None", doc: "how to flush ambiguous insertion positions. None (default): insertions not flushed. Right: insertions flushed to the right. STAR Fusion recommended (SF)"}
  alignIntronMax: {type: 'int?', default: 1000000, doc: "maximum intron size. SF recommends 100000"}
  alignMatesGapMax: {type: 'int?', default: 1000000, doc: "maximum genomic distance between mates, SF recommends 100000 to avoid readthru fusions within 100k"}
  alignSJDBoverhangMin: {type: 'int?', default: 1, doc: "minimum overhang for annotated junctions. SF recommends 10"}
  outFilterMismatchNmax: {type: 'int?', default: 999, doc: "maximum number of mismatches per pair, large number switches off this filter"}
  alignSJstitchMismatchNmax: {type: 'string?', default: "5 -1 5 5", doc: "maximum number of mismatches for stitching of the splice junctions. Value '5 -1 5 5' improves SF chimeric junctions, also recommended by arriba (AR)"}
  alignSplicedMateMapLmin: {type: 'int?', default: 0, doc: "minimum mapped length for a read mate that is spliced. SF recommends 30"}
  alignSplicedMateMapLminOverLmate: {type: 'float?', default: 0.5, doc: "alignSplicedMateMapLmin normalized to mate length. SF recommends 0, AR 0.5"}
  chimJunctionOverhangMin: {type: 'int?', default: 10, doc: "minimum overhang for a chimeric junction. SF recommends 8, AR 10"}
  chimMultimapNmax: {type: 'int?', default: 50, doc: "maximum number of chimeric multi-alignments. SF recommends 20, AR 50."}
  chimMultimapScoreRange: {type: 'int?', default: 1, doc: "the score range for multi-mapping chimeras below the best chimeric score. Only works with chimMultimapNmax > 1. SF recommends 3"}
  chimNonchimScoreDropMin: {type: 'int?', default: 20, doc: "int>=0: to trigger chimeric detection, the drop in the best non-chimeric alignment score with respect to the read length has to be greater than this value. SF recommends 10"}
  chimOutJunctionFormat: {type: 'int?', default: 1, doc: "formatting type for the Chimeric.out.junction file, value 1 REQUIRED for SF"}
  chimOutType: {type: ['null', {type: enum, name: chimOutType, symbols: ["Junctions SeparateSAMold WithinBAM SoftClip", "Junctions", "SeparateSAMold", "WithinBAM SoftClip", "WithinBAM HardClip", "Junctions SeparateSAMold", "Junctions WithinBAM SoftClip", "Junctions WithinBAM HardClip", "Junctions SeparateSAMold WithinBAM HardClip", "SeparateSAMold WithinBAM SoftClip", "SeparateSAMold WithinBAM HardClip"]}], default: "Junctions WithinBAM SoftClip", doc: "type of chimeric output. Args are additive, and defined as such - Junctions: Chimeric.out.junction. SeparateSAMold: output old SAM into separate Chimeric.out.sam file WithinBAM: output into main aligned BAM files (Aligned.*.bam). WithinBAM HardClip: hard-clipping in the CIGAR for supplemental chimeric alignments WithinBAM SoftClip:soft-clipping in the CIGAR for supplemental chimeric alignments"}
  chimScoreDropMax: {type: 'int?', default: 30, doc: "max drop (difference) of chimeric score (the sum of scores of all chimeric segments) from the read length. AR recommends 30"}
  chimScoreJunctionNonGTAG: {type: 'int?', default: -1, doc: "penalty for a non-GT/AG chimeric junction. default -1, SF recommends -4, AR -1"}
  chimScoreSeparation: {type: 'int?', default: 1, doc: "int>=0: minimum difference (separation) between the best chimeric score and the next one. AR recommends 1"}
  chimSegmentMin: {type: 'int?', default: 10, doc: "minimum length of chimeric segment length, if ==0, no chimeric output. REQUIRED for SF, 12 is their default, AR recommends 10"}
  chimSegmentReadGapMax: {type: 'int?', default: 3, doc: "maximum gap in the read sequence between chimeric segments. AR recommends 3"}
  outFilterMultimapNmax: {type: 'int?', default: 50, doc: "max number of multiple alignments allowed for a read: if exceeded, the read is considered unmapped. ENCODE value is default. AR recommends 50"}
  peOverlapMMp: {type: 'float?', default: 0.01, doc: "maximum proportion of mismatched bases in the overlap area. SF recommends 0.1"}
  peOverlapNbasesMin: {type: 'int?', default: 10, doc: "minimum number of overlap bases to trigger mates merging and realignment. Specify >0 value to switch on the 'merging of overlapping mates'algorithm. SF recommends 12,  AR recommends 10"}
```
### arriba:
```yaml
  arriba_memory: {type: 'int?', doc: "Mem intensive tool. Set in GB", default: 64}
```
### STAR Fusion:
```yaml
  FusionGenome: {type: 'File', doc: "STAR-Fusion CTAT Genome lib", "sbg:suggestedValue": {
      class: File, path: 62853e7ad63f7c6d8d7ae5a8, name: GRCh38_v39_CTAT_lib_Mar242022.CUSTOM.tar.gz}}
  compress_chimeric_junction: {type: 'boolean?', default: true, doc: 'If part of a
      workflow, recommend compressing this file as final output'}
```
### RNAseQC:
```yaml
  RNAseQC_GTF: {type: 'File', doc: "gtf file from `gtf_anno` that has been collapsed GTEx-style", "sbg:suggestedValue": {class: File, path: 62853e7ad63f7c6d8d7ae5a3,
      name: gencode.v39.primary_assembly.rnaseqc.stranded.gtf}}
```
### kallisto
```yaml
  kallisto_idx: {type: 'File', doc: "Specialized index of a **transcriptome** fasta file for kallisto", "sbg:suggestedValue": {class: File, path: 62853e7ad63f7c6d8d7ae5a6,
      name: RSEM_GENCODE39.transcripts.kallisto.idx}}
  kallisto_avg_frag_len: {type: 'int?', doc: "Optional input. Average fragment length for Kallisto only if single end input."}
  kallisto_std_dev: {type: 'long?', doc: "Optional input. Standard Deviation of the average fragment length for Kallisto only needed if single end input."}
```
### RSEM:
```yaml
  RSEMgenome: {type: 'File', doc: "RSEM reference tar ball", "sbg:suggestedValue": {
      class: File, path: 62853e7ad63f7c6d8d7ae5a5, name: RSEM_GENCODE39.tar.gz}}
  paired_end: {type: 'boolean?', doc: "If input is paired-end, add this flag", default: true}
  estimate_rspd: {type: 'boolean?', doc: "Set this option if you want to estimate the read start position distribution (RSPD) from data", default: true}
```
### annoFuse:
```yaml
  sample_name: {type: 'string', doc: "Sample ID of the input reads"}
  annofuse_col_num: {type: 'int?', doc: "column number in file of fusion name."}
```
### rmats
```yaml
  rmats_read_length: {type: 'int', doc: "Input read length for sample reads."}
  rmats_variable_read_length: {type: 'boolean?', doc: "Allow reads with lengths that differ from --readLength to be processed. --readLength will still be used to determine IncFormLen and SkipFormLen."}
  rmats_novel_splice_sites: {type: 'boolean?', doc: "Select for novel splice site detection or unannotated splice sites. 'true' to detect or add this parameter, 'false' to disable denovo detection. Tool Default: false"}
  rmats_stat_off: {type: 'boolean?', doc: "Select to skip statistical analysis, either between two groups or on single sample group. 'true' to add this parameter. Tool default: false"}
  rmats_allow_clipping: {type: 'boolean?', doc: "Allow alignments with soft or hard clipping to be used."}
  rmats_threads: {type: 'int?', doc: "Threads to allocate to RMATs."}
  rmats_ram: {type: 'int?', doc: "GB of RAM to allocate to RMATs."}
  rmats_read_type: {type: ['null', {type: enum, name: rmats_read_type, symbols: [
          "single", "paired"]}], default: "paired", doc: "Indicate whether input reads are single- or paired-end"}
```

### Run:

1) Reads inputs:
For PE fastq input, please enter the reads 1 file in `reads1` and the reads 2 file in `reads2`.
For SE fastq input, enter the single ends reads file in `reads1` and leave `reads2` empty as it is optional.
For bam input, please enter the reads file in `reads1` and leave `reads2` empty as it is optional.

2) `r1_adapter` and `r2_adapter` are OPTIONAL.
If the input reads have already been trimmed, leave these as null and cutadapt step will simple pass on the fastq files to STAR.
If they do need trimming, supply the adapters and the cutadapt step will trim, and pass trimmed fastqs along.

3) `wf_strand_param` is a workflow convenience param so that, if you input the following, the equivalent will propagate to the four tools that use that parameter:
    - `default`: 'rsem_std': null, 'kallisto_std': null, 'rnaseqc_std': null, 'arriba_std': null. This means unstranded or auto in the case of arriba.
    - `rf-stranded`: 'rsem_std': 0, 'kallisto_std': 'rf-stranded', 'rnaseqc_std': 'rf', 'arriba_std': 'reverse'.  This means if read1 in the input fastq/bam is reverse complement to the transcript that it maps to.
    - `fr-stranded`: 'rsem_std': 1, 'kallisto_std': 'fr-stranded', 'rnaseqc_std': 'fr', 'arriba_std': 'yes'. This means if read1 in the input fastq/bam is the same sense (maps 5' to 3') to the transcript that it maps to.

4) Suggested `STAR_outSAMattrRGline`, with **TABS SEPARATING THE TAGS**,  format is:

    `ID:sample_name LB:aliquot_id   PL:platform SM:BSID` for example `ID:7316-242   LB:750189 PL:ILLUMINA SM:BS_W72364MN`
5) Suggested REFERENCE inputs are:

    - `reference_fasta`: [GRCh38.primary_assembly.genome.fa](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/GRCh38.primary_assembly.genome.fa.gz), will need to unzip
    - `gtf_anno`: [gencode.v39.primary_assembly.annotation.gtf](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/gencode.v39.primary_assembly.annotation.gtf.gz), will need to unzip
    - `FusionGenome`: GRCh38_v39_CTAT_lib_Mar242022.CUSTOM.tar.gz. A custom library built using instructions from (https://github.com/STAR-Fusion/STAR-Fusion/wiki/installing-star-fusion#preparing-the-genome-resource-lib), using GENCODE 39 reference.
    - `RNAseQC_GTF`: gencode.v39.primary_assembly.rnaseqc.stranded.gtf OR gencode.v39.primary_assembly.rnaseqc.unstranded.gtf, built using `gtf_anno` and following build instructions [here](https://github.com/broadinstitute/rnaseqc#usage) and [here](https://github.com/broadinstitute/gtex-pipeline/tree/master/gene_model)
    - `RSEMgenome`: RSEM_GENCODE39.tar.gz, built using the `reference_fasta` and `gtf_anno`, following `GENCODE` instructions from [here](https://deweylab.github.io/RSEM/README.html), then creating a tar ball of the results.
    - `STARgenome`: STAR_2.7.10a_GENCODE39.tar.gz, created using the star_2.7.10a_genome_generate.cwl tool, using the `reference_fasta`, `gtf_anno`, and setting `sjdbOverhang` to 100
    - `kallisto_idx`: RSEM_GENCODE39.transcripts.kallisto.idx, built from RSEM GENCODE 39 transcript fasts, in `RSEMgenome` tar ball, following instructions from [here](https://pachterlab.github.io/kallisto/manual)

6) rMATS requires you provide the length of the reads in the sample. If you are unsure of the length, you can set `rmats_variable_read_length` to true which will allow reads with a length other than the value you provided to be processed.

### Outputs:
```yaml
  cutadapt_stats: {type: 'File?', outputSource: cutadapt_3-4/cutadapt_stats, doc: "Cutadapt stats output, only if adapter is supplied."}
  STAR_transcriptome_bam: {type: 'File', outputSource: star_2-7-10a/transcriptome_bam_out,
    doc: "STAR bam of transcriptome reads"}
  STAR_sorted_genomic_cram: {type: 'File', outputSource: samtools_bam_to_cram/output,
    doc: "STAR sorted and indexed genomic alignment cram"}
  STAR_chimeric_junctions: {type: 'File?', outputSource: star_fusion_1-10-1/chimeric_junction_compressed,
    doc: "STAR chimeric junctions"}
  STAR_gene_count: {type: 'File', outputSource: star_2-7-10a/gene_counts, doc: "STAR genecounts"}
  STAR_junctions_out: {type: 'File', outputSource: star_2-7-10a/junctions_out, doc: "STARjunction reads"}
  STAR_final_log: {type: 'File', outputSource: star_2-7-10a/log_final_out, doc: "STAR metricslog file of unique, multi-mapping, unmapped, and chimeric reads"}
  STAR-Fusion_results: {type: 'File', outputSource: star_fusion_1-10-1/abridged_coding,
    doc: "STAR fusion detection from chimeric reads"}
  arriba_fusion_results: {type: 'File', outputSource: arriba_fusion_2-2-1/arriba_fusions,
    doc: "Fusion output from Arriba"}
  arriba_fusion_viz: {type: 'File', outputSource: arriba_draw_2-2-1/arriba_pdf, doc: "pdf output from Arriba"}
  RSEM_isoform: {type: 'File', outputSource: rsem/isoform_out, doc: "RSEM isoform expression estimates"}
  RSEM_gene: {type: 'File', outputSource: rsem/gene_out, doc: "RSEM gene expression estimates"}
  RNASeQC_Metrics: {type: 'File', outputSource: rna_seqc/Metrics, doc: "Metrics on mapping, intronic, exonic rates, count information, etc"}
  RNASeQC_counts: {type: 'File', outputSource: supplemental/RNASeQC_counts, doc: "Contains gene tpm, gene read, and exon counts"}
  kallisto_Abundance: {type: 'File', outputSource: kallisto/abundance_out, doc: "Gene abundance output from STAR genomic bam file"}
  annofuse_filtered_fusions_tsv: {type: 'File?', outputSource: annofuse/annofuse_filtered_fusions_tsv,
    doc: "Filtered fusions called by annoFuse."}
  rmats_filtered_alternative_3_prime_splice_sites_jc: {type: 'File', outputSource: rmats/filtered_alternative_3_prime_splice_sites_jc,
    doc: "Alternative 3 prime splice sites JC.txt output from RMATs containing only those calls with 10 or more read counts of support"}
  rmats_filtered_alternative_5_prime_splice_sites_jc: {type: 'File', outputSource: rmats/filtered_alternative_5_prime_splice_sites_jc,
    doc: "Alternative 5 prime splice sites JC.txt output from RMATs containing only those calls with 10 or more read counts of support"}
  rmats_filtered_mutually_exclusive_exons_jc: {type: 'File', outputSource: rmats/filtered_mutually_exclusive_exons_jc,
    doc: "Mutually exclusive exons JC.txt output from RMATs containing only those calls with 10 or more read counts of support"}
  rmats_filtered_retained_introns_jc: {type: 'File', outputSource: rmats/filtered_retained_introns_jc,
    doc: "Retained introns JC.txt output from RMATs containing only those calls with 10 or more read counts of support"}
  rmats_filtered_skipped_exons_jc: {type: 'File', outputSource: rmats/filtered_skipped_exons_jc,
    doc: "Skipped exons JC.txt output from RMATs containing only those calls with 10 or more read counts of support"}
```

## Reference build notes:
 - STAR-Fusion reference built with command `/usr/local/STAR-Fusion/ctat-genome-lib-builder/prep_genome_lib.pl --gtf gencode.v39.primary_assembly.annotation.gtf --annot_filter_rule ../AnnotFilterRule.pm --CPU 36 --fusion_annot_lib ../fusion_lib.Mar2021.dat.gz --genome_fa ../GRCh38.primary_assembly.genome.fa --output_dir GRCh38_v39_CTAT_lib_Mar242022.CUSTOM --human_gencode_filter --pfam_db current --dfam_db human 2> build.errs > build.out &`
 - kallisto index built using RSEM `RSEM_GENCODE39.transcripts.fa` file as transcriptome fasta, using command: `kallisto index -i RSEM_GENCODE39.transcripts.kallisto.idx RSEM_GENCODE39.transcripts.fa`
 - RNA-SEQc reference built using [collapse gtf script](https://github.com/broadinstitute/gtex-pipeline/blob/master/gene_model/collapse_annotation.py)
   - Two references needed if data are stranded vs. unstranded
   - Flag `--collapse_only` used for stranded