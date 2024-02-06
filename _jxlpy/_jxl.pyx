# distutils: language = c++
# cython: language_level = 3

from libc.stdint cimport uint8_t, uint16_t, int32_t, uint32_t, int64_t, uint64_t
from libc.string cimport memset
from libcpp.vector cimport vector
from libcpp.utility cimport pair
import math

__version__ = '0.9.3'


cdef extern from 'jxl/types.h':

    ctypedef int JXL_BOOL

    int JXL_TRUE
    int JXL_FALSE

    ctypedef enum JxlDataType:
        JXL_TYPE_FLOAT
        JXL_TYPE_UINT8
        JXL_TYPE_UINT16
        JXL_TYPE_FLOAT16

    ctypedef enum JxlEndianness:
        JXL_NATIVE_ENDIAN
        JXL_LITTLE_ENDIAN
        JXL_BIG_ENDIAN

    ctypedef struct JxlPixelFormat:
        uint32_t num_channels
        JxlDataType data_type
        JxlEndianness endianness
        size_t align

    ctypedef enum JxlBitDepthType:
        JXL_BIT_DEPTH_FROM_PIXEL_FORMAT
        JXL_BIT_DEPTH_FROM_CODESTREAM
        JXL_BIT_DEPTH_CUSTOM

    ctypedef struct JxlBitDepth:
        JxlBitDepthType dtype 'type'
        uint32_t bits_per_sample
        uint32_t exponent_bits_per_sample

    ctypedef char JxlBoxType[4]


cdef extern from 'jxl/codestream_header.h':

    ctypedef enum JxlOrientation:
        JXL_ORIENT_IDENTITY
        JXL_ORIENT_FLIP_HORIZONTAL
        JXL_ORIENT_ROTATE_180
        JXL_ORIENT_FLIP_VERTICAL
        JXL_ORIENT_TRANSPOSE
        JXL_ORIENT_ROTATE_90_CW
        JXL_ORIENT_ANTI_TRANSPOSE
        JXL_ORIENT_ROTATE_90_CCW

    ctypedef enum JxlExtraChannelType:
        JXL_CHANNEL_ALPHA
        JXL_CHANNEL_DEPTH
        JXL_CHANNEL_SPOT_COLOR
        JXL_CHANNEL_SELECTION_MASK
        JXL_CHANNEL_BLACK
        JXL_CHANNEL_CFA
        JXL_CHANNEL_THERMAL
        JXL_CHANNEL_RESERVED0
        JXL_CHANNEL_RESERVED1
        JXL_CHANNEL_RESERVED2
        JXL_CHANNEL_RESERVED3
        JXL_CHANNEL_RESERVED4
        JXL_CHANNEL_RESERVED5
        JXL_CHANNEL_RESERVED6
        JXL_CHANNEL_RESERVED7
        JXL_CHANNEL_UNKNOWN
        JXL_CHANNEL_OPTIONAL

    ctypedef struct JxlPreviewHeader:
        uint32_t xsize
        uint32_t ysize

    ctypedef struct JxlAnimationHeader:
        uint32_t tps_numerator
        uint32_t tps_denominator
        uint32_t num_loops
        JXL_BOOL have_timecodes

    ctypedef struct JxlBasicInfo:
        JXL_BOOL have_container
        uint32_t xsize
        uint32_t ysize
        uint32_t bits_per_sample
        uint32_t exponent_bits_per_sample
        float intensity_target
        float min_nits
        JXL_BOOL relative_to_max_display
        float linear_below
        JXL_BOOL uses_original_profile
        JXL_BOOL have_preview
        JXL_BOOL have_animation
        JxlOrientation orientation
        uint32_t num_color_channels
        uint32_t num_extra_channels
        uint32_t alpha_bits
        uint32_t alpha_exponent_bits
        JXL_BOOL alpha_premultiplied
        JxlPreviewHeader preview
        JxlAnimationHeader animation
        uint32_t intrinsic_xsize
        uint32_t intrinsic_ysize

    ctypedef struct JxlExtraChannelInfo:
        JxlExtraChannelType type
        uint32_t bits_per_sample
        uint32_t exponent_bits_per_sample
        uint32_t dim_shift
        uint32_t name_length
        JXL_BOOL alpha_premultiplied
        float spot_color[4]
        uint32_t cfa_channel

    ctypedef struct JxlHeaderExtensions:
        uint64_t extensions

    ctypedef enum JxlBlendMode:
        JXL_BLEND_REPLACE
        JXL_BLEND_ADD
        JXL_BLEND_BLEND
        JXL_BLEND_MULADD
        JXL_BLEND_MUL

    ctypedef struct JxlBlendInfo:
        JxlBlendMode blendmode
        uint32_t source
        uint32_t alpha
        JXL_BOOL clamp

    ctypedef struct JxlLayerInfo:
        JXL_BOOL have_crop
        int32_t crop_x0
        int32_t crop_y0
        uint32_t xsize
        uint32_t ysize
        JxlBlendInfo blend_info
        uint32_t save_as_reference

    ctypedef struct JxlFrameHeader:
        uint32_t duration
        uint32_t timecode
        uint32_t name_length
        JXL_BOOL is_last
        JxlLayerInfo layer_info


cdef extern from 'jxl/color_encoding.h':

    ctypedef enum JxlColorSpace:
        JXL_COLOR_SPACE_RGB
        JXL_COLOR_SPACE_GRAY
        JXL_COLOR_SPACE_XYB
        JXL_COLOR_SPACE_UNKNOWN

    ctypedef enum JxlWhitePoint:
        JXL_WHITE_POINT_D65
        JXL_WHITE_POINT_CUSTOM
        JXL_WHITE_POINT_E
        JXL_WHITE_POINT_DCI

    ctypedef enum JxlPrimaries:
        JXL_PRIMARIES_SRGB
        JXL_PRIMARIES_CUSTOM
        JXL_PRIMARIES_2100
        JXL_PRIMARIES_P3

    ctypedef enum JxlTransferFunction:
        JXL_TRANSFER_FUNCTION_709
        JXL_TRANSFER_FUNCTION_UNKNOWN
        JXL_TRANSFER_FUNCTION_LINEAR
        JXL_TRANSFER_FUNCTION_SRGB
        JXL_TRANSFER_FUNCTION_PQ
        JXL_TRANSFER_FUNCTION_DCI
        JXL_TRANSFER_FUNCTION_HLG
        JXL_TRANSFER_FUNCTION_GAMMA

    ctypedef enum JxlRenderingIntent:
        JXL_RENDERING_INTENT_PERCEPTUAL
        JXL_RENDERING_INTENT_RELATIVE
        JXL_RENDERING_INTENT_SATURATION
        JXL_RENDERING_INTENT_ABSOLUTE

    ctypedef struct JxlColorEncoding:
        JxlColorSpace color_space
        JxlWhitePoint white_point
        double white_point_xy[2]
        JxlPrimaries primaries
        double primaries_red_xy[2]
        double primaries_green_xy[2]
        double primaries_blue_xy[2]
        JxlTransferFunction transfer_function
        double gamma
        JxlRenderingIntent rendering_intent

    ctypedef struct JxlInverseOpsinMatrix:
        float opsin_inv_matrix[3][3]
        float opsin_biases[3]
        float quant_biases[3]


cdef extern from 'jxl/memory_manager.h':

    ctypedef void* (*jpegxl_alloc_func)(
        void* opaque,
        size_t size
    ) nogil

    ctypedef void (*jpegxl_free_func)(
        void* opaque,
        void* address
    ) nogil

    ctypedef struct JxlMemoryManager:
        void* opaque
        jpegxl_alloc_func alloc
        jpegxl_free_func free


cdef extern from 'jxl/parallel_runner.h':

    ctypedef int JxlParallelRetCode

    int JXL_PARALLEL_RET_RUNNER_ERROR

    ctypedef JxlParallelRetCode (*JxlParallelRunInit)(
        void* jpegxl_opaque,
        size_t num_threads
    ) nogil

    ctypedef void (*JxlParallelRunFunction)(
        void* jpegxl_opaque,
        uint32_t value,
        size_t thread_id
    ) nogil

    ctypedef JxlParallelRetCode (*JxlParallelRunner)(
        void* runner_opaque,
        void* jpegxl_opaque,
        JxlParallelRunInit init,
        JxlParallelRunFunction func,
        uint32_t start_range,
        uint32_t end_range
    ) nogil


cdef extern from 'jxl/thread_parallel_runner.h':

    JxlParallelRetCode JxlThreadParallelRunner(
        void* runner_opaque,
        void* jpegxl_opaque,
        JxlParallelRunInit init,
        JxlParallelRunFunction func,
        uint32_t start_range,
        uint32_t end_range
    ) nogil

    void* JxlThreadParallelRunnerCreate(
        const JxlMemoryManager* memory_manager,
        size_t num_worker_threads
    ) nogil

    void JxlThreadParallelRunnerDestroy(
        void* runner_opaque
    ) nogil

    size_t JxlThreadParallelRunnerDefaultNumWorkerThreads() nogil


cdef extern from 'jxl/decode.h':

    uint32_t JxlDecoderVersion()

    ctypedef enum JxlSignature:
        JXL_SIG_NOT_ENOUGH_BYTES
        JXL_SIG_INVALID
        JXL_SIG_CODESTREAM
        JXL_SIG_CONTAINER

    JxlSignature JxlSignatureCheck(
        const uint8_t* buf,
        size_t len
    ) nogil

    ctypedef struct JxlDecoder:
        pass

    JxlDecoder* JxlDecoderCreate(
        const JxlMemoryManager* memory_manager
    ) nogil

    void JxlDecoderReset(
        JxlDecoder* dec
    ) nogil

    void JxlDecoderDestroy(
        JxlDecoder* dec
    ) nogil

    ctypedef enum JxlDecoderStatus:
        JXL_DEC_SUCCESS
        JXL_DEC_ERROR
        JXL_DEC_NEED_MORE_INPUT
        JXL_DEC_NEED_PREVIEW_OUT_BUFFER
        JXL_DEC_NEED_IMAGE_OUT_BUFFER
        JXL_DEC_JPEG_NEED_MORE_OUTPUT
        JXL_DEC_BASIC_INFO
        JXL_DEC_COLOR_ENCODING
        JXL_DEC_PREVIEW_IMAGE
        JXL_DEC_FRAME
        JXL_DEC_FULL_IMAGE
        JXL_DEC_JPEG_RECONSTRUCTION
        JXL_DEC_BOX
        JXL_DEC_FRAME_PROGRESSION

    ctypedef enum JxlProgressiveDetail:
        kFrames
        kDC
        kLastPasses
        kPasses
        kDCProgressive
        kDCGroups
        kGroups

    void JxlDecoderRewind(
        JxlDecoder* dec
    ) nogil

    void JxlDecoderSkipFrames(
        JxlDecoder* dec,
        size_t amount
    ) nogil

    JxlDecoderStatus JxlDecoderSkipCurrentFrame(
        JxlDecoder* dec
    ) nogil

    JxlDecoderStatus JxlDecoderSetParallelRunner(
        JxlDecoder* dec,
        JxlParallelRunner parallel_runner,
        void* parallel_runner_opaque
    ) nogil

    size_t JxlDecoderSizeHintBasicInfo(
        const JxlDecoder* dec
    ) nogil

    JxlDecoderStatus JxlDecoderSubscribeEvents(
        JxlDecoder* dec,
        int events_wanted
    ) nogil

    JxlDecoderStatus JxlDecoderSetKeepOrientation(
        JxlDecoder* dec,
        JXL_BOOL keep_orientation
    ) nogil

    JxlDecoderStatus JxlDecoderSetUnpremultiplyAlpha(
        JxlDecoder* dec,
        JXL_BOOL unpremul_alpha
    ) nogil

    JxlDecoderStatus JxlDecoderSetRenderSpotcolors(
        JxlDecoder* dec,
        JXL_BOOL render_spotcolors
    ) nogil

    JxlDecoderStatus JxlDecoderSetCoalescing(
        JxlDecoder* dec,
        JXL_BOOL coalescing
    ) nogil

    JxlDecoderStatus JxlDecoderProcessInput(
        JxlDecoder* dec
    ) nogil

    JxlDecoderStatus JxlDecoderSetInput(
        JxlDecoder* dec,
        const uint8_t* data,
        size_t size
    ) nogil

    size_t JxlDecoderReleaseInput(
        JxlDecoder* dec
    ) nogil

    void JxlDecoderCloseInput(
        JxlDecoder* dec
    ) nogil

    JxlDecoderStatus JxlDecoderGetBasicInfo(
        const JxlDecoder* dec,
        JxlBasicInfo* info
    ) nogil

    JxlDecoderStatus JxlDecoderGetExtraChannelInfo(
        const JxlDecoder* dec,
        size_t index,
        JxlExtraChannelInfo* info
    ) nogil

    JxlDecoderStatus JxlDecoderGetExtraChannelName(
        const JxlDecoder* dec,
        size_t index,
        char* name,
        size_t size
    ) nogil

    ctypedef enum JxlColorProfileTarget:
        JXL_COLOR_PROFILE_TARGET_ORIGINAL
        JXL_COLOR_PROFILE_TARGET_DATA

    JxlDecoderStatus JxlDecoderGetColorAsEncodedProfile(
        const JxlDecoder* dec,
        JxlColorProfileTarget target,
        JxlColorEncoding* color_encoding
    ) nogil

    JxlDecoderStatus JxlDecoderGetICCProfileSize(
        const JxlDecoder* dec,
        JxlColorProfileTarget target,
        size_t* size
    ) nogil

    JxlDecoderStatus JxlDecoderGetColorAsICCProfile(
        const JxlDecoder* dec,
        JxlColorProfileTarget target,
        uint8_t* icc_profile,
        size_t size
    ) nogil

    JxlDecoderStatus JxlDecoderSetPreferredColorProfile(
        JxlDecoder* dec,
        const JxlColorEncoding* color_encoding
    ) nogil

    JxlDecoderStatus JxlDecoderSetDesiredIntensityTarget(
        JxlDecoder* dec,
        float desired_intensity_target
    ) nogil

    JxlDecoderStatus JxlDecoderSetOutputColorProfile(
        JxlDecoder* dec,
        const JxlColorEncoding* color_encoding,
        const uint8_t* icc_data,
        size_t icc_size
    ) nogil
    
    JxlDecoderStatus JxlDecoderPreviewOutBufferSize(
        const JxlDecoder* dec,
        const JxlPixelFormat* format,
        size_t* size
    ) nogil

    JxlDecoderStatus JxlDecoderSetPreviewOutBuffer(
        JxlDecoder* dec,
        const JxlPixelFormat* format,
        void* buffer,
        size_t size
    ) nogil

    JxlDecoderStatus JxlDecoderGetFrameHeader(
        const JxlDecoder* dec,
        JxlFrameHeader* header
    ) nogil

    JxlDecoderStatus JxlDecoderGetFrameName(
        const JxlDecoder* dec,
        char* name,
        size_t size
    ) nogil

    JxlDecoderStatus JxlDecoderGetExtraChannelBlendInfo(
        const JxlDecoder* dec,
        size_t index,
        JxlBlendInfo* blend_info
    ) nogil

    JxlDecoderStatus JxlDecoderImageOutBufferSize(
        const JxlDecoder* dec,
        const JxlPixelFormat* format,
        size_t* size
    ) nogil

    JxlDecoderStatus JxlDecoderSetImageOutBuffer(
        JxlDecoder* dec,
        const JxlPixelFormat* format,
        void* buffer,
        size_t size
    ) nogil

    ctypedef void (*JxlImageOutCallback)(
        void* opaque,
        size_t x,
        size_t y,
        size_t num_pixels,
        const void* pixels
    ) nogil

    ctypedef void* (*JxlImageOutInitCallback)(
        void* init_opaque,
        size_t num_threads,
        size_t num_pixels_per_thread
    ) nogil

    ctypedef void (*JxlImageOutRunCallback)(
        void* run_opaque,
        size_t thread_id,
        size_t x,
        size_t y,
        size_t num_pixels,
        const void* pixels
    ) nogil

    ctypedef void (*JxlImageOutDestroyCallback)(
        void* run_opaque
    ) nogil

    JxlDecoderStatus JxlDecoderSetImageOutCallback(
        JxlDecoder* dec,
        const JxlPixelFormat* format,
        JxlImageOutCallback callback,
        void* opaque
    ) nogil

    JxlDecoderStatus JxlDecoderSetMultithreadedImageOutCallback(
        JxlDecoder* dec,
        const JxlPixelFormat* format,
        JxlImageOutInitCallback init_callback,
        JxlImageOutRunCallback run_callback,
        JxlImageOutDestroyCallback destroy_callback,
        void* init_opaque
    ) nogil

    JxlDecoderStatus JxlDecoderExtraChannelBufferSize(
        const JxlDecoder* dec,
        const JxlPixelFormat* format,
        size_t* size,
        uint32_t index
    ) nogil

    JxlDecoderStatus JxlDecoderSetExtraChannelBuffer(
        JxlDecoder* dec,
        const JxlPixelFormat* format,
        void* buffer,
        size_t size,
        uint32_t index
    ) nogil

    JxlDecoderStatus JxlDecoderSetJPEGBuffer(
        JxlDecoder* dec,
        uint8_t* data,
        size_t size
    ) nogil

    size_t JxlDecoderReleaseJPEGBuffer(
        JxlDecoder* dec
    ) nogil

    JxlDecoderStatus JxlDecoderSetBoxBuffer(
        JxlDecoder* dec,
        uint8_t* data,
        size_t size
    ) nogil

    size_t JxlDecoderReleaseBoxBuffer(
        JxlDecoder* dec
    ) nogil

    JxlDecoderStatus JxlDecoderSetDecompressBoxes(
        JxlDecoder* dec,
        JXL_BOOL decompress
    ) nogil

    JxlDecoderStatus JxlDecoderGetBoxType(
        JxlDecoder* dec,
        JxlBoxType type,
        JXL_BOOL decompressed
    ) nogil

    JxlDecoderStatus JxlDecoderGetBoxSizeRaw(
        const JxlDecoder* dec,
        uint64_t* size
    ) nogil

    JxlDecoderStatus JxlDecoderSetProgressiveDetail(
        JxlDecoder* dec,
        JxlProgressiveDetail detail
    ) nogil

    JxlDecoderStatus JxlDecoderFlushImage(
        JxlDecoder* dec
    ) nogil

    JxlDecoderStatus JxlDecoderSetImageOutBitDepth(
        JxlDecoder* dec,
        const JxlBitDepth* bit_depth
    ) nogil


cdef extern from 'jxl/encode.h':

    uint32_t JxlEncoderVersion()

    ctypedef struct JxlEncoder:
        pass

    ctypedef struct JxlEncoderFrameSettings:
        pass

    ctypedef enum JxlEncoderStatus:
        JXL_ENC_SUCCESS
        JXL_ENC_ERROR
        JXL_ENC_NEED_MORE_OUTPUT

    ctypedef enum JxlEncoderError:
        JXL_ENC_ERR_OK
        JXL_ENC_ERR_GENERIC
        JXL_ENC_ERR_OOM
        JXL_ENC_ERR_JBRD
        JXL_ENC_ERR_BAD_INPUT
        JXL_ENC_ERR_NOT_SUPPORTED
        JXL_ENC_ERR_API_USAGE

    ctypedef enum JxlEncoderFrameSettingId:
        JXL_ENC_FRAME_SETTING_EFFORT
        JXL_ENC_FRAME_SETTING_DECODING_SPEED
        JXL_ENC_FRAME_SETTING_RESAMPLING
        JXL_ENC_FRAME_SETTING_EXTRA_CHANNEL_RESAMPLING
        JXL_ENC_FRAME_SETTING_ALREADY_DOWNSAMPLED
        JXL_ENC_FRAME_SETTING_PHOTON_NOISE
        JXL_ENC_FRAME_SETTING_NOISE
        JXL_ENC_FRAME_SETTING_DOTS
        JXL_ENC_FRAME_SETTING_PATCHES
        JXL_ENC_FRAME_SETTING_EPF
        JXL_ENC_FRAME_SETTING_GABORISH
        JXL_ENC_FRAME_SETTING_MODULAR
        JXL_ENC_FRAME_SETTING_KEEP_INVISIBLE
        JXL_ENC_FRAME_SETTING_GROUP_ORDER
        JXL_ENC_FRAME_SETTING_GROUP_ORDER_CENTER_X
        JXL_ENC_FRAME_SETTING_GROUP_ORDER_CENTER_Y
        JXL_ENC_FRAME_SETTING_RESPONSIVE
        JXL_ENC_FRAME_SETTING_PROGRESSIVE_AC
        JXL_ENC_FRAME_SETTING_QPROGRESSIVE_AC
        JXL_ENC_FRAME_SETTING_PROGRESSIVE_DC
        JXL_ENC_FRAME_SETTING_CHANNEL_COLORS_GLOBAL_PERCENT
        JXL_ENC_FRAME_SETTING_CHANNEL_COLORS_GROUP_PERCENT
        JXL_ENC_FRAME_SETTING_PALETTE_COLORS
        JXL_ENC_FRAME_SETTING_LOSSY_PALETTE
        JXL_ENC_FRAME_SETTING_COLOR_TRANSFORM
        JXL_ENC_FRAME_SETTING_MODULAR_COLOR_SPACE
        JXL_ENC_FRAME_SETTING_MODULAR_GROUP_SIZE
        JXL_ENC_FRAME_SETTING_MODULAR_PREDICTOR
        JXL_ENC_FRAME_SETTING_MODULAR_MA_TREE_LEARNING_PERCENT
        JXL_ENC_FRAME_SETTING_MODULAR_NB_PREV_CHANNELS
        JXL_ENC_FRAME_SETTING_JPEG_RECON_CFL
        JXL_ENC_FRAME_INDEX_BOX
        JXL_ENC_FRAME_SETTING_BROTLI_EFFORT
        JXL_ENC_FRAME_SETTING_JPEG_COMPRESS_BOXES
        JXL_ENC_FRAME_SETTING_BUFFERING
        JXL_ENC_FRAME_SETTING_JPEG_KEEP_EXIF
        JXL_ENC_FRAME_SETTING_JPEG_KEEP_XMP
        JXL_ENC_FRAME_SETTING_JPEG_KEEP_JUMBF
        JXL_ENC_FRAME_SETTING_FILL_ENUM

    JxlEncoder* JxlEncoderCreate(
        const JxlMemoryManager* memory_manager
    ) nogil

    void JxlEncoderReset(
        JxlEncoder* enc
    ) nogil

    void JxlEncoderDestroy(
        JxlEncoder* enc
    ) nogil

    JxlEncoderStatus JxlEncoderSetParallelRunner(
        JxlEncoder* enc,
        JxlParallelRunner parallel_runner,
        void* parallel_runner_opaque
    ) nogil

    JxlEncoderError JxlEncoderGetError(
        JxlEncoder* enc
    ) nogil

    JxlEncoderStatus JxlEncoderProcessOutput(
        JxlEncoder* enc,
        uint8_t** next_out,
        size_t* avail_out
    ) nogil

    JxlEncoderStatus JxlEncoderSetFrameHeader(
        JxlEncoderFrameSettings* frame_settings,
        const JxlFrameHeader* frame_header
    ) nogil

    JxlEncoderStatus JxlEncoderSetExtraChannelBlendInfo(
        JxlEncoderFrameSettings* frame_settings,
        size_t index,
        const JxlBlendInfo* blend_info
    ) nogil

    JxlEncoderStatus JxlEncoderSetFrameName(
        JxlEncoderFrameSettings* frame_settings,
        const char* frame_name
    ) nogil

    JxlEncoderStatus JxlEncoderSetFrameBitDepth(
        JxlEncoderFrameSettings* frame_settings,
        const JxlBitDepth* bit_depth
    ) nogil

    JxlEncoderStatus JxlEncoderAddJPEGFrame(
        const JxlEncoderFrameSettings* frame_settings,
        const uint8_t* buffer,
        size_t size
    ) nogil

    JxlEncoderStatus JxlEncoderAddImageFrame(
        const JxlEncoderFrameSettings* frame_settings,
        const JxlPixelFormat* pixel_format,
        const void* buffer,
        size_t size
    ) nogil

    struct JxlEncoderOutputProcessor:
        void* opaque

        void* (*get_buffer)(
            void* opaque,
            size_t* size
        ) nogil

        void (*release_buffer)(
            void* opaque,
            size_t written_bytes
        ) nogil

        void (*seek)(
            void* opaque,
            uint64_t position
        ) nogil

        void (*set_finalized_position)(
            void* opaque,
            uint64_t finalized_position
        ) nogil

    JxlEncoderStatus JxlEncoderSetOutputProcessor(
        JxlEncoder* enc,
        JxlEncoderOutputProcessor output_processor
    ) nogil

    JxlEncoderStatus JxlEncoderFlushInput(
        JxlEncoder* enc
    ) nogil

    struct JxlChunkedFrameInputSource:
        void* opaque

        void (*get_color_channels_pixel_format)(
            void* opaque,
            JxlPixelFormat* pixel_format
        ) nogil

        const void* (*get_color_channel_data_at)(
            void* opaque,
            size_t xpos,
            size_t ypos,
            size_t xsize,
            size_t ysize,
            size_t* row_offset
        ) nogil

        void (*get_extra_channel_pixel_format)(
            void* opaque,
            size_t ec_index,
            JxlPixelFormat* pixel_format
        ) nogil

        const void* (*get_extra_channel_data_at)(
            void* opaque,
            size_t ec_index,
            size_t xpos,
            size_t ypos,
            size_t xsize,
            size_t ysize,
            size_t* row_offset
        ) nogil

        void (*release_buffer)(
            void* opaque,
            const void* buf
        ) nogil

    JxlEncoderStatus JxlEncoderAddChunkedFrame(
        const JxlEncoderFrameSettings* frame_settings,
        JXL_BOOL is_last_frame,
        JxlChunkedFrameInputSource chunked_frame_input
    ) nogil

    JxlEncoderStatus JxlEncoderSetExtraChannelBuffer(
        const JxlEncoderFrameSettings* frame_settings,
        const JxlPixelFormat* pixel_format,
        const void* buffer,
        size_t size,
        uint32_t index
    ) nogil

    JxlEncoderStatus JxlEncoderAddBox(
        JxlEncoder* enc,
        const JxlBoxType type,
        const uint8_t* contents,
        size_t size,
        JXL_BOOL compress_box
    ) nogil

    JxlEncoderStatus JxlEncoderUseBoxes(
        JxlEncoder* enc
    ) nogil

    void JxlEncoderCloseBoxes(
        JxlEncoder* enc
    ) nogil

    void JxlEncoderCloseFrames(
        JxlEncoder* enc
    ) nogil

    void JxlEncoderCloseInput(
        JxlEncoder* enc
    ) nogil

    JxlEncoderStatus JxlEncoderSetColorEncoding(
        JxlEncoder* enc,
        const JxlColorEncoding* color
    ) nogil

    JxlEncoderStatus JxlEncoderSetICCProfile(
        JxlEncoder* enc,
        const uint8_t* icc_profile,
        size_t size
    ) nogil

    void JxlEncoderInitBasicInfo(
        JxlBasicInfo* info
    ) nogil

    void JxlEncoderInitFrameHeader(
        JxlFrameHeader* frame_header
    ) nogil

    void JxlEncoderInitBlendInfo(
        JxlBlendInfo* blend_info
    ) nogil

    JxlEncoderStatus JxlEncoderSetBasicInfo(
        JxlEncoder* enc,
        const JxlBasicInfo* info
    ) nogil

    JxlEncoderStatus JxlEncoderSetUpsamplingMode(
        JxlEncoder* enc,
        const int64_t factor,
        const int64_t mode
    ) nogil

    void JxlEncoderInitExtraChannelInfo(
        JxlExtraChannelType type,
        JxlExtraChannelInfo* info
    ) nogil

    JxlEncoderStatus JxlEncoderSetExtraChannelInfo(
        JxlEncoder* enc,
        size_t index,
        const JxlExtraChannelInfo* info
    ) nogil

    JxlEncoderStatus JxlEncoderSetExtraChannelName(
        JxlEncoder* enc,
        size_t index,
        const char* name,
        size_t size
    ) nogil

    JxlEncoderStatus JxlEncoderFrameSettingsSetOption(
        JxlEncoderFrameSettings* frame_settings,
        JxlEncoderFrameSettingId option,
        int64_t value
    ) nogil

    JxlEncoderStatus JxlEncoderFrameSettingsSetFloatOption(
        JxlEncoderFrameSettings* frame_settings,
        JxlEncoderFrameSettingId option,
        float value
    ) nogil

    JxlEncoderStatus JxlEncoderUseContainer(
        JxlEncoder* enc,
        JXL_BOOL use_container
    ) nogil

    JxlEncoderStatus JxlEncoderStoreJPEGMetadata(
        JxlEncoder* enc,
        JXL_BOOL store_jpeg_metadata
    ) nogil

    JxlEncoderStatus JxlEncoderSetCodestreamLevel(
        JxlEncoder* enc,
        int level
    ) nogil

    int JxlEncoderGetRequiredCodestreamLevel(
        const JxlEncoder* enc
    ) nogil

    JxlEncoderStatus JxlEncoderSetFrameLossless(
        JxlEncoderFrameSettings* frame_settings,
        JXL_BOOL lossless
    ) nogil


    JxlEncoderStatus JxlEncoderSetFrameDistance(
        JxlEncoderFrameSettings* frame_settings,
        float distance
    ) nogil

    JxlEncoderStatus JxlEncoderSetExtraChannelDistance(
        JxlEncoderFrameSettings* frame_settings,
        size_t index,
        float distance
    ) nogil

    float JxlEncoderDistanceFromQuality(
        float quality
    ) nogil

    JxlEncoderFrameSettings* JxlEncoderFrameSettingsCreate(
        JxlEncoder* enc,
        const JxlEncoderFrameSettings* source
    ) nogil

    void JxlColorEncodingSetToSRGB(
        JxlColorEncoding* color_encoding,
        JXL_BOOL is_gray
    ) nogil

    void JxlColorEncodingSetToLinearSRGB(
        JxlColorEncoding* color_encoding,
        JXL_BOOL is_gray
    ) nogil


class JXLPyError(Exception):

    def __init__(self, msg, code=None):

        if code is not None:
            msg += msg + " (error code: {})".format(code)
        super().__init__(msg)


class JxlPyArgumentInvalid(Exception):

    def __init__(self, argument, _range: tuple=None):
    
        if _range is not None:
            argument += ' (should be in range {}..{})'.format(_range[0], _range[1])
        super().__init__(argument)


cdef uint32_t _cver = JxlDecoderVersion()

_jxl_version = '{}.{}.{}'.format(_cver//1000000, (_cver//1000)%1000, _cver%1000)


def _check_arg(value, name, _range: tuple):

    if value < _range[0] or value > _range[1]:
        raise JxlPyArgumentInvalid(name, _range)


def get_distance(quality: int) -> float:

    distance = None
    
    if quality == 100:
        return 0
    
    if quality >= 10:
        if quality >= 30:
            distance = 0.1 + (100 - quality) * 0.09
        else:
            distance = 6.4 + (2.5 ** ((30-quality) / 5.0)) / 6.25
    else:
        # non standard formula (the original one gives distance above 15)
        distance = 12.65 + (0.235 * (10 - quality))

    return distance


# TODO: EXIF support
cdef class JXLPyEncoder:

    cdef uint8_t* src
    cdef void* runner
    cdef JxlEncoder* encoder
    cdef JxlEncoderFrameSettings* options
    cdef JxlEncoderStatus status
    cdef JxlBasicInfo basic_info
    cdef JxlPixelFormat pixel_format
    cdef JxlColorEncoding color_encoding
    cdef size_t num_threads
    cdef int colorspace

    # quality: 0..100 -> quality of the image like in JPEG or other formats
    #                    the smaller the worse and 100 is lossless
    #                    WARNING: quality below 10 is non standard to keep distance below 15
    #                             you really should use higher values for quality
    # size -> image size in pixels (w, h)
    # effort: 3..9 -> speed/(quality&size) tradeoff,
    #                 3 being the fastest and 9 being really slow (7 is recommended)
    # decoding_speed: 0..4 -> decoding speed speed/(quality&size) tradeoff,
    #                         decoding is fast even on level 0 (the slowest one)
    # use_container -> if True, JXL encoder will wrap image data into JXL contaier (recommended)
    # colorspace -> for now only RGB, RGBA, L, LA are supported
    # endianness -> can be little, big or native
    # num_threads: 0..n -> leaving 0 (default) will use all available cpu threads,
    #                      setting it to fixed number (t) will use only t threads
    #                      it is recommended to keep n <= $threads_of_your_cpu
    def __init__(self, quality: int, size: tuple, effort: int=7, decoding_speed: int=0,
                 use_container: bool=True, colorspace: str='RGB', endianness: str='native',
                 num_threads: int=0):

        _check_arg(quality, 'quality', (0, 100))
        _check_arg(effort, 'effort', (3, 9))
        _check_arg(decoding_speed, 'decoding_speed', (0, 4))
        _check_arg(num_threads, 'num_threads', (0, 32))

        memset(<void*> &self.basic_info, 0, sizeof(JxlBasicInfo))
        memset(<void*> &self.pixel_format, 0, sizeof(JxlPixelFormat))
        memset(<void*> &self.color_encoding, 0, sizeof(JxlColorEncoding))

        JxlEncoderInitBasicInfo(&self.basic_info)

        lossless = bool(quality==100)

        self.status = JXL_ENC_SUCCESS
        self.colorspace = -1;

        self.encoder = JxlEncoderCreate(NULL)
        if self.encoder == NULL:
            JXLPyError("JxlEncoderCreate")

        if num_threads == 0:
            self.num_threads = JxlThreadParallelRunnerDefaultNumWorkerThreads()
        else:
            self.num_threads = num_threads
        
        self.runner = JxlThreadParallelRunnerCreate(NULL, num_threads)
        if self.runner == NULL:
            raise JXLPyError('JxlThreadParallelRunnerCreate')
        
        self.status = JxlEncoderSetParallelRunner(
            self.encoder, JxlThreadParallelRunner, self.runner
        )
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderSetParallelRunner', self.status)
        
        # TODO: allow other colorspaces
        if colorspace == 'RGB':
            self.colorspace = JXL_COLOR_SPACE_RGB
            self.basic_info.num_color_channels = 3
            samples = 3
        elif colorspace == 'RGBA':
            self.colorspace = JXL_COLOR_SPACE_RGB
            self.basic_info.num_color_channels = 3
            self.basic_info.alpha_bits = 8
            samples = 4
        elif colorspace == 'L':
            self.colorspace = JXL_COLOR_SPACE_GRAY
            self.basic_info.num_color_channels = 1
            samples = 1
        elif colorspace == 'LA':
            self.colorspace = JXL_COLOR_SPACE_GRAY
            self.basic_info.num_color_channels = 1
            self.basic_info.alpha_bits = 8
            samples = 2
        else:
            raise JxlPyArgumentInvalid('Unknown colorspace.')
        
        self.basic_info.xsize = <uint32_t> size[0]
        self.basic_info.ysize = <uint32_t> size[1]
        self.basic_info.num_extra_channels = (
            <uint32_t> samples - self.basic_info.num_color_channels
        )
        # TODO: support higher bit-depth
        self.basic_info.bits_per_sample = 8
        #self.basic_info.have_animation = JXL_TRUE   # animation support doesn't work?
        #self.basic_info.animation.tps_numerator = 100
        #self.basic_info.animation.tps_denominator = 1
        
        if lossless:
            self.basic_info.uses_original_profile = JXL_TRUE
        else:
            self.basic_info.uses_original_profile = JXL_FALSE
        
        self.status = JxlEncoderSetBasicInfo(self.encoder, &self.basic_info)
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderSetBasicInfo', self.status)
        
        self.pixel_format.data_type = JXL_TYPE_UINT8
        self.pixel_format.num_channels = <uint32_t> samples
        
        if endianness == 'little':
            self.pixel_format.endianness = JXL_LITTLE_ENDIAN
        elif endianness == 'big':
            self.pixel_format.endianness = JXL_BIG_ENDIAN
        elif endianness == 'native':
            self.pixel_format.endianness = JXL_NATIVE_ENDIAN
        else:
            raise JxlPyArgumentInvalid('endianness')
        
        self.pixel_format.align = 0  # TODO: allow strides
        
        if self.pixel_format.data_type == JXL_TYPE_UINT8:
            JxlColorEncodingSetToSRGB(
                &self.color_encoding, self.colorspace == JXL_COLOR_SPACE_GRAY
            )
        else:
            JxlColorEncodingSetToLinearSRGB(
                &self.color_encoding, self.colorspace == JXL_COLOR_SPACE_GRAY
            )

        self.status = JxlEncoderSetColorEncoding(self.encoder, &self.color_encoding)
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderSetColorEncoding', self.status)

        self.status = JxlEncoderUseContainer(self.encoder, use_container)
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderUseContainer', self.status)

        self.options = JxlEncoderFrameSettingsCreate(self.encoder, NULL)
        if self.options == NULL:
            raise JXLPyError('JxlEncoderFrameSettingsCreate')

        distance = get_distance(quality)

        self.status = JxlEncoderSetFrameLossless(self.options, lossless)
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderSetFrameLossless', self.status)

        self.status = JxlEncoderSetFrameDistance(self.options, distance)
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderSetFrameDistance', self.status)

        self.status = JxlEncoderFrameSettingsSetOption(self.options, JXL_ENC_FRAME_SETTING_DECODING_SPEED, decoding_speed)
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderFrameSettingsSetOption', self.status)

        self.status = JxlEncoderFrameSettingsSetOption(self.options, JXL_ENC_FRAME_SETTING_EFFORT, effort)
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderFrameSettingsSetOption', self.status)


    def add_frame(self, input_data: bytes):

        self.src = input_data

        # TODO: add animation support
        self.status = JxlEncoderAddImageFrame(
            self.options,
            &self.pixel_format,
            <void*> self.src,
            self.basic_info.xsize * self.basic_info.ysize \
            * math.ceil(self.basic_info.bits_per_sample/8) \
            * (self.basic_info.num_color_channels + self.basic_info.num_extra_channels)
        )
        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderAddImageFrame', self.status)
        
        return True

    def get_output(self):
        JxlEncoderCloseFrames(self.encoder)
    
        cdef vector[uint8_t] compressed
        compressed.resize(64)
        cdef uint8_t* next_out = <uint8_t*>compressed.data()
        cdef size_t avail_out = compressed.size() - (next_out - compressed.data())
        cdef size_t offset
        
        self.status = JXL_ENC_NEED_MORE_OUTPUT
        
        while self.status == JXL_ENC_NEED_MORE_OUTPUT:

            self.status = JxlEncoderProcessOutput(
                self.encoder, &next_out, &avail_out
            )
            
            if self.status == JXL_ENC_NEED_MORE_OUTPUT:
                offset = next_out - compressed.data()
                compressed.resize(compressed.size() * 2)
                next_out = compressed.data() + offset
                avail_out = compressed.size() - offset

        compressed.resize(next_out - compressed.data())
        
        if next_out != NULL and self.encoder != NULL:
            JxlEncoderCloseInput(self.encoder)

        if self.status != JXL_ENC_SUCCESS:
            raise JXLPyError('JxlEncoderProcessOutput', self.status)
        
        return compressed.data()[:compressed.size()]

    def __dealloc__(self):
        if self.encoder != NULL:
            JxlEncoderDestroy(self.encoder)
        if self.runner != NULL:
            JxlThreadParallelRunnerDestroy(self.runner)

    # keeping the close function for legacy reasons
    # it's not necessary thanks to https://github.com/olokelo/jxlpy/issues/12
    def close(self):
        pass


# TODO: test higher bit depths
cdef class JXLPyDecoder(object):

    cdef uint8_t* src
    cdef void* runner
    cdef size_t buffer_size
    cdef JxlDecoder* decoder
    cdef JxlDecoderStatus status
    cdef JxlSignature signature
    cdef JxlBasicInfo basic_info
    cdef JxlPixelFormat pixel_format
    cdef size_t num_threads
    cdef bint decoding_finished

    def __init__(self, jxl_data: bytes, keep_orientation: bool=True, num_threads: int=0):
        
        self.src = jxl_data
        self.decoding_finished = False
        src_len = len(jxl_data)
        
        self.signature = JxlSignatureCheck(self.src, src_len)
        if self.signature != JXL_SIG_CODESTREAM and self.signature != JXL_SIG_CONTAINER:
            raise ValueError('not a JPEG XL codestream')

        memset(<void*> &self.basic_info, 0, sizeof(JxlBasicInfo))
        memset(<void*> &self.pixel_format, 0, sizeof(JxlPixelFormat))

        self.decoder = JxlDecoderCreate(NULL);
        if self.decoder == NULL:
            raise JXLPyError('JxlDecoderCreate')
        
        if num_threads == 0:
            self.num_threads = JxlThreadParallelRunnerDefaultNumWorkerThreads()
        else:
            self.num_threads = num_threads
        
        self.runner = JxlThreadParallelRunnerCreate(NULL, num_threads)
        if self.runner == NULL:
            raise JXLPyError('JxlThreadParallelRunnerCreate')
        
        self.status = JxlDecoderSetParallelRunner(
            self.decoder, JxlThreadParallelRunner, self.runner
        )
        if self.status != JXL_DEC_SUCCESS:
            raise JXLPyError('JxlDecoderSetParallelRunner', self.status)
        
        self.status = JxlDecoderSubscribeEvents(
            self.decoder, JXL_DEC_BASIC_INFO | JXL_DEC_FULL_IMAGE
        )
        if self.status != JXL_DEC_SUCCESS:
            raise JXLPyError('JxlDecoderSubscribeEvents', self.status)

        if keep_orientation:
            self.status = JxlDecoderSetKeepOrientation(self.decoder, JXL_TRUE)
            if self.status != JXL_DEC_SUCCESS:
                raise JXLPyError('JxlDecoderSetKeepOrientation', self.status)

        self.status = JxlDecoderSetInput(self.decoder, self.src, src_len)
        if self.status != JXL_DEC_SUCCESS:
            raise JXLPyError('JxlDecoderSetInput', self.status)


    def get_colorspace(self):
        self.get_info()
        
        # TODO: add more colorspace information by analysing JXL_DEC_COLOR_ENCODING
        if self.basic_info.alpha_bits > 0:
            if self.basic_info.num_color_channels == 3:
                if self.basic_info.alpha_premultiplied:
                    return 'RGBa'
                return 'RGBA'
            if self.basic_info.num_color_channels == 1:
                if self.basic_info.alpha_premultiplied:
                    return 'La'
                return 'LA'
        if self.basic_info.num_color_channels == 3:
            return 'RGB'
        if self.basic_info.num_color_channels == 1:
            return 'L'
        raise JxlPyArgumentInvalid("Unknown colorspace.")

    # returns Python dictionary converted by cython
    def get_info(self):

        # size of the image cannot be 0 so I assume this means basic_info is not initialized
        if self.basic_info.xsize == 0:

            self.status = JxlDecoderProcessInput(self.decoder)
            
            if (self.status == JXL_DEC_ERROR or self.status == JXL_DEC_NEED_MORE_INPUT):
                raise JXLPyError('JxlDecoderProcessInput', self.status)

            if self.status == JXL_DEC_BASIC_INFO:

                self.status = JxlDecoderGetBasicInfo(self.decoder, &self.basic_info)
                if self.status != JXL_DEC_SUCCESS:
                    raise JXLPyError('JxlDecoderGetBasicInfo', self.status)

                samples = (self.basic_info.num_color_channels + self.basic_info.num_extra_channels)
                self.pixel_format.num_channels = <uint32_t> samples
                self.pixel_format.endianness = JXL_NATIVE_ENDIAN
                self.pixel_format.align = 0
                
                if self.basic_info.exponent_bits_per_sample > 0:
                    self.pixel_format.data_type = JXL_TYPE_FLOAT
                    if self.basic_info.bits_per_sample == 16:
                        print('float 16 bits')
                    elif self.basic_info.bits_per_sample == 32:
                        print('float 32 bits')
                    elif self.basic_info.bits_per_sample == 64:
                        print('float 64 bits')
                    # TODO: add floating point support
                    raise NotImplementedError('Floating point decoding not supported')

                elif self.basic_info.bits_per_sample <= 8:
                    self.pixel_format.data_type = JXL_TYPE_UINT8
                elif self.basic_info.bits_per_sample <= 16:
                    self.pixel_format.data_type = JXL_TYPE_UINT16
                elif self.basic_info.bits_per_sample <= 32:
                    self.pixel_format.data_type = JXL_TYPE_FLOAT

            else:
                # TODO: write the correct way to get information about an image
                #       JXLDecoderReset???
                raise NotImplementedError('basic_info not found at current state')

        return self.basic_info


    def get_frame(self):

        cdef JxlExtraChannelInfo extra_info
        cdef vector[uint8_t] data_out
        cdef vector[uint8_t] extra_out[8];

        if self.decoding_finished:
            return None

        self.get_info()
        
        data_out.resize(
            self.basic_info.xsize * self.basic_info.ysize \
            * math.ceil(self.basic_info.bits_per_sample/8) \
            * (self.basic_info.num_color_channels + self.basic_info.num_extra_channels)
        )

        while True:
            self.status = JxlDecoderProcessInput(self.decoder)
            
            if (self.status == JXL_DEC_ERROR or self.status == JXL_DEC_NEED_MORE_INPUT):
                raise JXLPyError('JxlDecoderProcessInput', self.status)
            
            if self.status == JXL_DEC_FULL_IMAGE:
                break

            if self.status == JXL_DEC_SUCCESS:
                self.decoding_finished = True
                return None

            if self.status == JXL_DEC_BASIC_INFO:
                raise RuntimeError('This should not happen here')
                
            if self.status == JXL_DEC_NEED_IMAGE_OUT_BUFFER:
                self.status = JxlDecoderImageOutBufferSize(
                    self.decoder, &self.pixel_format, &self.buffer_size
                )
                if self.status != JXL_DEC_SUCCESS:
                    raise JXLPyError('JxlDecoderImageOutBufferSize', self.status)
                
                if self.buffer_size != <size_t> data_out.size():
                    raise RuntimeError('buffer_size != data_out.size()')
                
                self.status = JxlDecoderSetImageOutBuffer(
                    self.decoder, &self.pixel_format, data_out.data(), self.buffer_size
                )
                if self.status != JXL_DEC_SUCCESS:
                    raise JXLPyError('JxlDecoderSetImageOutBuffer', self.status)

        return data_out.data()[:data_out.size()]


    def __dealloc__(self):
        if self.decoder != NULL:
            JxlDecoderDestroy(self.decoder)
        if self.runner != NULL:
            JxlThreadParallelRunnerDestroy(self.runner)

    def close(self):
        pass

