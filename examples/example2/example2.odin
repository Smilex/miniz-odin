package example2

import miniz "../../"
import "core:fmt"
import "core:c"
import "core:os"
import "core:strings"
import "core:mem"

g_str :=
    "MISSION CONTROL I wouldn't worry too much about the computer. First of all, there is still a chance that he is right, despite your tests, and" +
    "if it should happen again, we suggest eliminating this possibility by allowing the unit to remain in place and seeing whether or not it" +
    "actually fails. If the computer should turn out to be wrong, the situation is still not alarming. The type of obsessional error he may be" +
    "guilty of is not unknown among the latest generation of HAL 9000 computers. It has almost always revolved around a single detail, such as" +
    "the one you have described, and it has never interfered with the integrity or reliability of the computer's performance in other areas." +
    "No one is certain of the cause of this kind of malfunctioning. It may be over-programming, but it could also be any number of reasons. In any" +
    "event, it is somewhat analogous to human neurotic behavior. Does this answer your query?  Zero-five-three-Zero, MC, transmission concluded."

g_comment := "This is a comment"

main :: proc () {
    i, sort_iter: i32
    status: b32
    uncomp_size: c.size_t
    zip_archive: miniz.zip_archive
    p: rawptr
    N :: 50
    data: [2048]c.char
    archive_filename: [64]c.char
    test_archive_filename := "__mz_example2_test__.zip"

    assert((len(g_str) + 64) < size_of(data));

    fmt.printf("miniz.odin version: %s\n", miniz.VERSION)

    os.remove(test_archive_filename)

    for i = (N - 1); i >= 0; i -= 1 {
        archive_len := len(fmt.bprintf(archive_filename[:], "%v.txt", i))
        data_len := c.size_t(len(fmt.bprintf(data[:], "%v %s %v", (N - 1) - i, g_str, i)))

        archive_filename[archive_len] = 0
        data[data_len] = 0

        status = miniz.zip_add_mem_to_archive_file_in_place(strings.unsafe_string_to_cstring(test_archive_filename), cstring(&archive_filename[0]),
            &data[0], data_len + 1, raw_data(g_comment), u16(len(g_comment)), miniz.BEST_COMPRESSION)

        if !status {
            panic("mz_zip_add_mem_to_archive_file_in_place failed!")
        }
    }

    no_comment := "no comment"
    status = miniz.zip_add_mem_to_archive_file_in_place(strings.unsafe_string_to_cstring(test_archive_filename), "directory/", nil, 0, raw_data(no_comment), cast(u16)len(no_comment), miniz.BEST_COMPRESSION);
    if (!status)
    {
        panic("mz_zip_add_mem_to_archive_file_in_place failed!")
    }

    miniz.zip_zero_struct(&zip_archive)

    status = miniz.zip_reader_init_file(&zip_archive, strings.unsafe_string_to_cstring(test_archive_filename), 0);
    if (!status)
    {
        panic("mz_zip_reader_init_file() failed!")
    }

    for i = 0; i < i32(miniz.zip_reader_get_num_files(&zip_archive)); i += 1 {
        file_stat: miniz.zip_archive_file_stat
        if !miniz.zip_reader_file_stat(&zip_archive, u32(i), &file_stat) {
            miniz.zip_reader_end(&zip_archive);
            panic("mz_zip_reader_file_stat() failed!");
        }

        filename := strings.truncate_to_byte(string(file_stat.m_filename[:]), 0)

        fmt.printf("Filename: \"%s\", Comment: \"%s\", Uncompressed size: %v, Compressed size: %v, Is Dir: %v\n", filename, cstring(&file_stat.m_comment[0]), file_stat.m_uncomp_size, file_stat.m_comp_size, miniz.zip_reader_is_file_a_directory(&zip_archive, u32(i)));

        if strings.compare(filename, "directory/") == 0 {
            if !miniz.zip_reader_is_file_a_directory(&zip_archive, u32(i)) {
                miniz.zip_reader_end(&zip_archive);
                panic("mz_zip_reader_is_file_a_directory() didn't return the expected results!")
            }
        }
    }

    miniz.zip_reader_end(&zip_archive)

    for sort_iter = 0; sort_iter < 2; sort_iter += 1 {
        miniz.zip_zero_struct(&zip_archive);
        flags := u32(0)
        if sort_iter > 0 {
            flags = u32(miniz.zip_flags.DO_NOT_SORT_CENTRAL_DIRECTORY)
        }
        status = miniz.zip_reader_init_file(&zip_archive, strings.unsafe_string_to_cstring(test_archive_filename), flags);
        if (!status)
        {
            panic("mz_zip_reader_init_file() failed!")
        }

        for i = 0; i < N; i += 1 {
            archive_len := len(fmt.bprintf(archive_filename[:], "%v.txt", i))
            data_len := len(fmt.bprintf(data[:], "%v %s %v", (N - 1) - i, g_str, i))

            archive_filename[archive_len] = 0
            data[data_len] = 0

            p = miniz.zip_reader_extract_file_to_heap(&zip_archive, cstring(&archive_filename[0]), &uncomp_size, 0);
            if p == nil {
                miniz.zip_reader_end(&zip_archive);
                panic("mz_zip_reader_extract_file_to_heap() failed!");
            }

            // Make sure the extraction really succeeded.
            if uncomp_size != uint(data_len + 1) || mem.compare_ptrs(p, &data[0], data_len) != 0 {
                miniz.zip_reader_end(&zip_archive);
                fmt.panicf("mz_zip_reader_extract_file_to_heap() failed to extract the proper data. %v != %v?", uncomp_size, uint(data_len + 1))
            }

            fmt.printf("Successfully extracted file \"%s\", size %v\n", string(archive_filename[:archive_len]), uncomp_size)
            fmt.printf("File data: \"%s\"\n", cstring(p));

            miniz.free(p);
        }

        miniz.zip_reader_end(&zip_archive);
    }

    fmt.printf("Success.");
}
