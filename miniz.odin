package miniz

import c "core:c"

@(private)
LIB :: (
	     "lib/miniz.lib"      when ODIN_OS == .Windows
	else "lib/miniz.a"        when ODIN_OS == .Linux
	else "lib/darwin/miniz.a" when ODIN_OS == .Darwin
	else "lib/miniz_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		#panic("Could not find the compiled MINIZ library, it can be compiled in the src/ directory")
	}
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import miniz "lib/miniz_wasm.o"
} else when LIB != "" {
	foreign import miniz { LIB }
} else {
	foreign import miniz "system:miniz"
}

VERSION :: "11.0.2"
VERNUM :: 0xB002
VER_MAJOR :: 11
VER_MINOR :: 2
VER_REVISION :: 0
VER_SUBREVISION :: 0

status :: enum i32 {
    OK = 0,
    STREAM_END = 1,
    NEED_DICT = 2,
    ERRNO = -1,
    STREAM_ERROR = -2,
    DATA_ERROR = -3,
    MEM_ERROR = -4,
    BUF_ERROR = -5,
    VERSION_ERROR = -6,
    PARAM_ERROR = -10000,
}

/* Note: These enums can be reduced as needed to save memory or stack space - they are pretty conservative. */
ZIP_MAX_IO_BUF_SIZE :: 64 * 1024
ZIP_MAX_ARCHIVE_FILENAME_SIZE :: 512
ZIP_MAX_ARCHIVE_FILE_COMMENT_SIZE :: 512

TINFL_MAX_HUFF_TABLES :: 3
TINFL_MAX_HUFF_SYMBOLS_0 :: 288
TINFL_MAX_HUFF_SYMBOLS_1 :: 32
TINFL_MAX_HUFF_SYMBOLS_2 :: 19
TINFL_FAST_LOOKUP_BITS :: 10
TINFL_FAST_LOOKUP_SIZE :: 1 << TINFL_FAST_LOOKUP_BITS

NO_COMPRESSION :: 0
BEST_SPEED :: 1
BEST_COMPRESSION :: 9
UBER_COMPRESSION :: 10
DEFAULT_LEVEL :: 6
DEFAULT_COMPRESSION :: -1

/*
   typedef unsigned char mz_uint8;
typedef int16_t mz_int16;
typedef uint16_t mz_uint16;
typedef uint32_t mz_uint32;
typedef uint32_t mz_uint;
typedef int64_t mz_int64;
typedef uint64_t mz_uint64;
typedef int mz_bool;
*/

#assert(size_of(c.int) == size_of(b32))

zip_internal_state :: distinct rawptr
time_t :: distinct i64
tinfl_bit_buf_t :: distinct u64

@(default_calling_convention="c", link_prefix="mz_")
foreign miniz {
    zip_reader_init :: proc (pZip: ^zip_archive, size: u64, flags: u32) -> b32 ---
    zip_reader_init_mem :: proc (pZip: ^zip_archive, pMem: rawptr, size: c.size_t, flags: u32) -> b32 ---
    when ODIN_ARCH != .wasm32 && ODIN_ARCH != .wasm64p32 {
        zip_reader_init_file :: proc (pZip: ^zip_archive, pFilename: cstring, flags: u32) -> b32 ---
        zip_reader_init_file_v2 :: proc (pZip: ^zip_archive, pFilename: cstring, flags: u32, file_start_ofs: u64, archive_size: u64) -> b32 ---
        zip_reader_init_cfile :: proc (pZip: ^zip_archive, pFile: ^c.FILE, flags: u32) -> b32 ---

        zip_reader_extract_to_file :: proc (pZip: ^zip_archive, file_index: u32, pDst_filename: cstring, flags: u32) -> b32 ---
        zip_reader_extract_file_to_file :: proc (pZip: ^zip_archive, pArchive_filename: cstring, pDst_filename: cstring, flags: u32) -> b32 ---
        zip_reader_extract_to_cfile :: proc (pZip: ^zip_archive, file_index: u32, pFile: ^c.FILE, flags: u32) -> b32 ---
        zip_reader_extract_file_to_cfile :: proc (pZip: ^zip_archive, pArchive_filename: cstring, pFile: ^c.FILE, flags: u32) -> b32 ---

        zip_validate_file_archive :: proc (pFilename: cstring, flags: u32, pErr: ^zip_error) -> b32 ---

        zip_writer_init_file :: proc (pZip: ^zip_archive, pFilename: cstring, size_to_reserve_at_beginning: u64) -> b32 ---
        zip_writer_init_file_v2 :: proc (pZip: ^zip_archive, pFilename: cstring, size_to_reserve_at_beginning: u64, flags: u32) -> b32 ---
        zip_writer_init_cfile :: proc (pZip: ^zip_archive, pFile: ^c.FILE, flags: u32) -> b32 ---

        zip_writer_add_file :: proc (pZip: ^zip_archive, pArchive_name: cstring, pSrc_filename: cstring, pComment: rawptr, comment_size: u16, level_and_flags: u32) -> b32 ---
        zip_writer_add_cfile :: proc (pZip: ^zip_archive, pArchive_name: cstring, pSrc_file: ^c.FILE, max_size: u64, #by_ptr pFile_time: time_t, pComment: rawptr, comment_size: u16, level_and_flags: u32, user_extra_data_local: cstring, user_extra_data_local_len: u32, user_extra_data_central: cstring, user_extra_data_central_len: u32) -> b32 ---

        zip_extract_archive_file_to_heap :: proc (pZip_filename: cstring, pArchive_name: cstring, pSize: ^c.size_t, flags: u32) -> rawptr ---
        zip_extract_archive_file_to_heap_v2 :: proc (pZip_filename: cstring, pArchive_name: cstring, pComment: cstring, pSize: ^c.size_t, flags: u32, pErr: ^zip_error) -> rawptr ---

    }
    zip_reader_end :: proc (pZip: ^zip_archive) -> b32 ---

    zip_zero_struct :: proc (pZip: ^zip_archive) ---
    zip_get_mode :: proc (pZip: ^zip_archive) -> zip_mode ---
    zip_get_type :: proc (pZip: ^zip_archive) -> zip_type ---
    zip_reader_get_num_files :: proc (pZip: ^zip_archive) -> u32 ---
    zip_get_archive_size :: proc(pZip: ^zip_archive) -> u64 ---
    zip_get_archive_file_start_offset :: proc (pZip: ^zip_archive) -> u64 ---
    zip_get_cfile :: proc (pZip: ^zip_archive) -> ^c.FILE ---

    zip_read_archive_data :: proc (pZip: ^zip_archive, file_ofs: u64, pBuf: rawptr, n: c.size_t) -> c.size_t ---

    zip_set_last_error :: proc (pZip: ^zip_archive, err_num: zip_error) -> zip_error ---
    zip_peek_last_error :: proc (pZip: ^zip_archive) -> zip_error ---
    zip_clear_last_error :: proc (pZip: ^zip_archive) -> zip_error ---
    zip_get_last_error :: proc (pZip: ^zip_archive) -> zip_error ---
    zip_get_error_string :: proc (mz_err: zip_error) -> cstring ---

    zip_reader_is_file_a_directory :: proc (pZip: ^zip_archive, file_index: u32) -> b32 ---
    zip_reader_is_file_encrypted :: proc (pZip: ^zip_archive, file_index: u32) -> b32 ---
    zip_reader_is_file_supported :: proc (pZip: ^zip_archive, file_index: u32) -> b32 ---

    zip_reader_get_filename :: proc(pZip: ^zip_archive, file_index: u32, pFilename: [^]c.char, filename_buf_size: u32) -> u32 ---

    zip_reader_locate_file :: proc (pZip: ^zip_archive, pName: cstring, pComment: cstring, flags: u32) -> c.int ---
    zip_reader_locate_file_v2 :: proc (pZip: ^zip_archive, pName: cstring, pComment: cstring, flags: u32, file_index: ^u32) -> b32 ---

    zip_reader_file_stat :: proc (pZip: ^zip_archive, file_index: u32, pStat: ^zip_archive_file_stat) -> b32 ---

    zip_is_zip64 :: proc (pZip: ^zip_archive) -> b32 ---

    zip_get_central_dir_size :: proc (pZip: ^zip_archive) -> c.size_t ---

    zip_reader_extract_to_mem_no_alloc :: proc (pZip: ^zip_archive, file_index: u32, pBuf: rawptr, buf_size: c.size_t, flags: u32, pUser_read_buf: rawptr, user_read_buf_size: c.size_t) -> b32 ---
    zip_reader_extract_file_to_mem_no_alloc :: proc (pZip: ^zip_archive, pFilename: cstring, pBuf: rawptr, buf_size: c.size_t, flags: u32, pUser_read_buf: rawptr, user_read_buf_size: c.size_t) -> b32 ---
    zip_reader_extract_to_mem :: proc (pZip: ^zip_archive, file_index: u32, pBuf: rawptr, buf_size: c.size_t, flags: u32) -> b32 ---
    zip_reader_extract_file_to_mem :: proc (pZip: ^zip_archive, pFilename: cstring, pBuf: rawptr, buf_size: c.size_t, flags: u32) -> b32 ---
    zip_reader_extract_to_heap :: proc (pZip: ^zip_archive, file_index: u32, pSize: ^c.size_t, flags: u32) -> rawptr ---
    zip_reader_extract_file_to_heap :: proc (pZip: ^zip_archive, pFilename: cstring, pSize: ^c.size_t, flags: u32) -> rawptr ---
    zip_reader_extract_to_callback :: proc (pZip: ^zip_archive, file_index: u32, pCallback: ^file_write_func, pOpaque: rawptr, flags: u32) -> b32 ---
    zip_reader_extract_file_to_callback :: proc (pZip: ^zip_archive, pFilename: cstring, pCallback: ^file_write_func, pOpaque: rawptr, flags: u32) -> b32 ---
    zip_reader_extract_iter_new :: proc (pZip: ^zip_archive, file_index: u32, flags: u32) -> ^zip_reader_extract_iter_state ---
    zip_reader_extract_file_iter_new :: proc (pZip: ^zip_archive, pFilename: cstring, flags: u32) -> ^zip_reader_extract_iter_state ---
    zip_reader_extract_iter_read :: proc (pState: ^zip_reader_extract_iter_state, pvBuf: rawptr, buf_size: c.size_t) -> c.size_t ---
    zip_reader_extract_iter_free :: proc (pState: ^zip_reader_extract_iter_state) -> b32 ---

    zip_validate_file :: proc (pZip: ^zip_archive, file_index: u32, flags: u32) -> b32 ---
    zip_validate_archive :: proc (pZip: ^zip_archive, flags: u32) -> b32 ---
    zip_validate_mem_archive :: proc (pMem: rawptr, size: c.size_t, flags: u32, pErr: ^zip_error) -> b32 ---
    zip_end :: proc (pZip: ^zip_archive) -> b32 ---

    zip_writer_init :: proc (pZip: ^zip_archive, existing_size: u64) -> b32 ---
    zip_writer_init_v2 :: proc (pZip: ^zip_archive, existing_size: u64, flags: u32) -> b32 ---
    zip_writer_init_heap :: proc (pZip: ^zip_archive, size_to_reserve_at_beginning: c.size_t, initial_allocation_size: c.size_t) -> b32 ---
    zip_writer_init_heap_v2 :: proc (pZip: ^zip_archive, size_to_reserve_at_beginning: c.size_t, initial_allocation_size: c.size_t, flags: u32) -> b32 ---

    zip_writer_init_from_reader :: proc (pZip: ^zip_archive, pFilename: cstring) -> b32 ---
    zip_writer_init_from_reader_v2 :: proc (pZip: ^zip_archive, pFilename: cstring, flags: u32) -> b32 ---
    zip_writer_add_mem :: proc (pZip: ^zip_archive, pArchive_name: cstring, pBuf: rawptr, buf_size: c.size_t, level_and_flags: u32) -> b32 ---
    zip_writer_add_mem_ex :: proc (pZip: ^zip_archive, pArchive_name: cstring, pBuf: rawptr, buf_size: c.size_t, pComment: cstring, comment_size: u16, level_and_flags: u32, uncomp_size: u64, uncomp_crc32: u32) -> b32 ---
    zip_writer_add_mem_ex_v2 :: proc (pZip: ^zip_archive, pArchive_name: cstring, pBuf: rawptr, buf_size: c.size_t, pComment: cstring, comment_size: u16, level_and_flags: u32, uncomp_size: u64, uncomp_crc32: u32, last_modified: ^time_t, user_extra_data_local: cstring, user_extra_data_local_len: u32, user_extra_data_central: cstring, user_extra_data_central_len: u32) -> b32 ---
    zip_writer_add_read_buf_callback :: proc (pZip: ^zip_archive, pArchive_name: cstring, read_callback: ^file_read_func, callback_opaque: rawptr, max_size: u64, #by_ptr pFile_time: time_t, pComment: rawptr, comment_size: u16, level_and_flags: u32, user_extra_data_local: cstring, user_extra_data_local_len: u32, user_extra_data_central: cstring, user_extra_data_central_len: u32) -> b32 ---

    zip_writer_add_from_zip_reader :: proc (pZip: ^zip_archive, pSource_zip: ^zip_archive, src_file_index: u32) -> b32 ---
    zip_writer_finalize_archive :: proc (pZip: ^zip_archive) -> b32 ---
    zip_writer_finalize_heap_archive :: proc (pZip: ^zip_archive, ppBuf: ^rawptr, pSize: ^c.size_t) -> b32 ---
    zip_writer_end :: proc (pZip: ^zip_archive) -> b32 ---

    zip_add_mem_to_archive_file_in_place :: proc (pZip_filename: cstring, pArchive_name: cstring, pBuf: rawptr, buf_size: c.size_t, pComment: rawptr, comment_size: u16, level_and_flags: u32) -> b32 ---
    zip_add_mem_to_archive_file_in_place_v2 :: proc (pZip_filename: cstring, pArchive_name: cstring, pBuf: rawptr, buf_size: c.size_t, pComment: rawptr, comment_size: u16, level_and_flags: u32, pErr: zip_error) -> b32 ---

    compressBound :: proc (source_len: u64) -> u64 ---
    compress :: proc (pDest: [^]u8, pDest_Len: ^u64, pSource: cstring, source_len: u64) -> status ---
    uncompress :: proc (pDest: [^]u8, pDest_Len: ^u64, pSource: cstring, source_len: u64) -> status ---
    free :: proc (p: rawptr) ---
}



zip_archive :: struct {
    m_archive_size: u64,
    m_central_directory_file_ofs: u64,

    m_total_files: u32,
    m_zip_mode: zip_mode,
    m_zip_type: zip_type,
    m_last_error: zip_error,

    m_file_offset_alignment: u64,

    m_pAlloc: ^alloc_func,
    m_pFree: ^free_func,
    m_pRealloc: ^realloc_func,
    m_pAlloc_opaque: rawptr,

    m_pRead: ^file_read_func,
    m_pWrite: ^file_write_func,
    m_pNeeds_keepalive: ^file_needs_keepalive,
    m_pIO_opaque: rawptr,

    m_pState: zip_internal_state,
}

zip_archive_file_stat :: struct {
    m_file_index: u32,
    m_central_dir_ofs: u64,

    m_version_made_by: u16,
    m_version_needed: u16,
    m_bit_flag: u16,
    m_method: u16,

    m_crc32: u32,
    m_comp_size: u64,
    m_uncomp_size: u64,

    m_internal_attr: u16,
    m_external_attr: u32,

    m_local_header_ofs: u64,
    m_comment_size: u32,

    m_is_directory: b32,
    m_is_encrypted: b32,
    m_is_supported: b32,

    m_filename: [ZIP_MAX_ARCHIVE_FILENAME_SIZE]c.char,
    m_comment: [ZIP_MAX_ARCHIVE_FILE_COMMENT_SIZE]c.char,

    m_time: time_t,
}

zip_reader_extract_iter_state :: struct {
    pZip: ^zip_archive,
    flags: u32,

    status: c.int,

    read_buf_size, read_buf_ofs, read_buf_avail, comp_remaining, out_buf_ofs, cur_file_ofs: u64,
    file_stat: zip_archive_file_stat,
    pRead_buf: rawptr,
    pWrite_buf: rawptr,

    out_blk_remain: c.size_t,

    inflator: tinfl_decompressor,

    file_crc32: u32,
}

tinfl_decompressor :: struct {
    m_state, m_num_bits, m_zhdr0, m_zhdr1, m_z_adler32, m_final, m_type, m_check_adler32, m_dist, m_counter, m_num_extra: u32,
    m_table_sizes: [TINFL_MAX_HUFF_TABLES]u32,
    m_bit_buf: tinfl_bit_buf_t,
    m_dist_from_out_buf_start: c.size_t,
    m_look_up: [TINFL_MAX_HUFF_TABLES][TINFL_FAST_LOOKUP_SIZE]i16,
    m_tree_0: [TINFL_MAX_HUFF_SYMBOLS_0 * 2]i16,
    m_tree_1: [TINFL_MAX_HUFF_SYMBOLS_1 * 2]i16,
    m_tree_2: [TINFL_MAX_HUFF_SYMBOLS_2 * 2]i16,
    m_code_size_0: [TINFL_MAX_HUFF_SYMBOLS_0]u8,
    m_code_size_1: [TINFL_MAX_HUFF_SYMBOLS_1]u8,
    m_code_size_2: [TINFL_MAX_HUFF_SYMBOLS_2]u8,
    m_raw_header: [4]u8,
    m_len_codes: [TINFL_MAX_HUFF_SYMBOLS_0 + TINFL_MAX_HUFF_SYMBOLS_1 + 137]u8,
}

zip_mode :: enum i32 {
    INVALID = 0,
    READING = 1,
    WRITING = 2,
    WRITING_HAS_BEEN_FINALIZED = 3
}

zip_type :: enum i32 {
    INVALID = 0,
    USER,
    MEMORY,
    HEAP,
    FILE,
    CFILE,
}

zip_error :: enum i32 {
    NO_ERROR = 0,
    UNDEFINED_ERROR,
    TOO_MANY_FILES,
    FILE_TOO_LARGE,
    UNSUPPORTED_METHOD,
    UNSUPPORTED_ENCRYPTION,
    UNSUPPORTED_FEATURE,
    FAILED_FINDING_CENTRAL_DIR,
    NOT_AN_ARCHIVE,
    INVALID_HEADER_OR_CORRUPTED,
    UNSUPPORTED_MULTIDISK,
    DECOMPRESSION_FAILED,
    COMPRESSION_FAILED,
    UNEXPECTED_DECOMPRESSED_SIZE,
    CRC_CHECK_FAILED,
    UNSUPPORTED_CDIR_SIZE,
    ALLOC_FAILED,
    FILE_OPEN_FAILED,
    FILE_CREATE_FAILED,
    FILE_WRITE_FAILED,
    FILE_READ_FAILED,
    FILE_CLOSE_FAILED,
    FILE_SEEK_FAILED,
    FILE_STAT_FAILED,
    INVALID_PARAMETER,
    INVALID_FILENAME,
    BUF_TOO_SMALL,
    INTERNAL_ERROR,
    FILE_NOT_FOUND,
    ARCHIVE_TOO_LARGE,
    VALIDATION_FAILED,
    WRITE_CALLBACK_FAILED,
    TOTAL_ERRORS
}

zip_flags :: enum i32 {
    CASE_SENSITIVE = 0x0100,
    IGNORE_PATH = 0x0200,
    COMPRESSED_DATA = 0x0400,
    DO_NOT_SORT_CENTRAL_DIRECTORY = 0x0800,
    VALIDATE_LOCATE_FILE_FLAG = 0x1000,
    VALIDATE_HEADERS_ONLY = 0x2000,
    WRITE_ZIP64 = 0x4000,
    WRITE_ALLOW_READING = 0x8000,
    ASCII_FILENAME = 0x10000,
    WRITE_HEADER_SET_SIZE = 0x20000,
    READ_ALLOW_WRITING = 0x40000
}

alloc_func :: proc "c" (mz_opaque: rawptr, items: c.size_t, size: c.size_t)
free_func :: proc "c" (mz_opaque: rawptr, address: rawptr)
realloc_func :: proc "c" (mz_opaque: rawptr, address: rawptr, items: c.size_t, size: c.size_t);

file_read_func :: proc "c" (pOpaque: rawptr, file_ofs: u64, pBuf: rawptr, n: c.size_t) -> c.size_t
file_write_func :: proc "c" (pOpaque: rawptr, file_ofs: u64, pBuf: rawptr, n: c.size_t) -> c.size_t
file_needs_keepalive :: proc "c" (pOpaque: rawptr) -> c.int
