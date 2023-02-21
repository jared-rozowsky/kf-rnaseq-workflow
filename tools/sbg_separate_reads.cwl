cwlVersion: v1.2
class: CommandLineTool
id: sbg-separate-reads
label: "SBG Separate Reads""
requirements:
  - class: InlineJavascriptRequirement
  
baseCommand: []
inputs:
  - id: in_reads
    type: 'File[]'
    label: Input reads
    doc: >-
      Reads can be supplied either as an aligned file (SAM, BAM, CRAM), or as a
      single end FASTQ file, or as two paired end FASTQ files.
    'sbg:fileTypes': 'FQ, FASTQ, BAM, CRAM'
outputs:
  - id: out_read1
    type: File
    outputBinding:
      outputEval: |-
        ${
            // Check if it is a single input. If it is, return only one file
            if(inputs.in_reads.length == 1)
                return inputs.in_reads[0]
            // If there are multiple inputs. Check for if there are exactly two inputs
            if (inputs.in_reads.length !== 2) {
              throw new Error("Input reads must have at most two elements.");
            }
            // If there are exactly two elements, check for metadata
            if(inputs.in_reads[0].metadata['paired_end'] == '1')
                return inputs.in_reads[0]
            if(inputs.in_reads[0].metadata['paired_end'] == '2')
                return inputs.in_reads[1]
            throw new Error("Metadata for Input Reads not set properly. If there are two input_reads files, they must have 'paired_end' metadata field set to either 1 or 2.");
        }
  - id: out_read2
    type: File?
    outputBinding:
      outputEval: |-
        ${
            // Check if there are exactlty two files:
            if(inputs.in_reads.length !== 2)
                return null
                
            if(inputs.in_reads[0].metadata['paired_end'] == '2')
                return inputs.in_reads[0]
            if(inputs.in_reads[1].metadata['paired_end'] == '2')
                return inputs.in_reads[1]
            throw new Error("Metadata for Input Reads not set properly. If there are two input_reads files, they must have 'paired_end' metadata field set to either 1 or 2. In this run, no files had metadata set to 2");
        }
doc: >-
  **SBG Separate Reads** splits a list of input reads into single files based on
  metadata. This app also handles cases when there is a single input file.


  ### Common Use Cases


  **SBG Separate Reads** is designed to enable batching of apps which take
  paired end reads as multiple inputs. It handles the following cases:

  * In case of a single file on the input, it propagates it to **out_read1**

  * In case of two files, it checks for metadata. If there is no metadata, it
  raises an error

  * If both files have proper metadata, file with *paired_end==1* will be
  propagated to **out_read1**, and *paired_end==2* to **out_read2**

  * In case of more than two files, it raises an error.


  ## Important notes and known issues


  * The app currently does not handle secondary files.

  * App does not check for input file type when a single input is given. It can
  therefor propagate files other than reads or alignments.


