//
// Read QC and trimming
//

include { FASTQC as FASTQC_RAW          } from '../../../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_TRIM         } from '../../../modules/nf-core/fastqc/main'
include { CUTADAPT as CUTADAPT_BARCODE  } from '../../../modules/nf-core/cutadapt/main'
include { CUTADAPT as CUTADAPT_READ     } from '../../../modules/nf-core/cutadapt/main'
include { CUTADAPT_POLYA                } from '../../../modules/local/cutadapt_polya/main'


workflow FASTQ_TRIM_CUTADAPT_FASTQC {
    take:
    ch_reads                 // channel: [ val(meta), path(reads)  ]
    val_skip_cutadapt        // value: boolean
    val_skip_fastqc          // value: boolean

    main:

    ch_versions = Channel.empty()

    ch_fastqc_raw_html = Channel.empty()
    ch_fastqc_raw_zip  = Channel.empty()
    if (!val_skip_fastqc) {
        FASTQC_RAW ( ch_reads )
        ch_fastqc_raw_html = FASTQC_RAW.out.html
        ch_fastqc_raw_zip  = FASTQC_RAW.out.zip
        ch_versions        = ch_versions.mix(FASTQC_RAW.out.versions.first())
    }

    ch_trim_reads        = ch_reads
    ch_trim_logs         = Channel.empty()
    ch_fastqc_trim_html  = Channel.empty()
    ch_fastqc_trim_zip   = Channel.empty()
    if (!val_skip_cutadapt) {
        CUTADAPT_BARCODE ( ch_reads )
        CUTADAPT_READ    ( CUTADAPT_BARCODE.out.reads )
        // CUTADAPT_POLYA   ( CUTADAPT_READ.out.reads.map { meta, reads -> [ meta, reads.reverse() ] } )
        CUTADAPT_POLYA   ( CUTADAPT_READ.out.reads )

        // ch_trim_reads = CUTADAPT_POLYA.out.reads.map { meta, reads -> [ meta, reads.reverse() ] }.view()

        ch_trim_reads = CUTADAPT_POLYA.out.reads
        ch_trim_logs  = CUTADAPT_POLYA.out.log.mix(CUTADAPT_READ.out.log)
                                              .mix(CUTADAPT_BARCODE.out.log)
        ch_versions   = ch_versions.mix(CUTADAPT_BARCODE.out.versions.first())
                                   .mix(CUTADAPT_READ.out.versions.first())
                                   .mix(CUTADAPT_POLYA.out.versions.first())

        if (!val_skip_fastqc) {
            FASTQC_TRIM ( ch_trim_reads )
            ch_fastqc_trim_html = FASTQC_TRIM.out.html
            ch_fastqc_trim_zip  = FASTQC_TRIM.out.zip
            ch_versions         = ch_versions.mix(FASTQC_TRIM.out.versions.first())
        }
    }

    emit:
    reads     = ch_trim_reads // channel: [ val(meta), path(reads) ]
    trim_logs = ch_trim_logs  // channel: [ val(meta), path(logs) ]

    fastqc_raw_html  = ch_fastqc_raw_html  // channel: [ val(meta), path(html) ]
    fastqc_raw_zip   = ch_fastqc_raw_zip   // channel: [ val(meta), path(zip) ]
    fastqc_trim_html = ch_fastqc_trim_html // channel: [ val(meta), path(html) ]
    fastqc_trim_zip  = ch_fastqc_trim_zip  // channel: [ val(meta), path(zip) ]

    versions = ch_versions.ifEmpty(null) // channel: [ path(versions.yml) ]
}
