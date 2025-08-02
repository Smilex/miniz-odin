package example1

import miniz "../../"
import "core:fmt"
import "core:strings"
import "core:math/rand"
import "core:mem"

g_str := "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." +
            "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." +
            "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." +
            "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." +
            "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." +
            "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." +
            "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson."

main :: proc () {
    step := u32(0)
    cmp_status: miniz.status
    src_len := u64(len(g_str))
    cmp_len := miniz.compressBound(src_len)
    uncomp_len := src_len
    p_cmp, p_uncomp: []u8
    total_succeeded := u32(0)

    fmt.printf("miniz version: %s\n", miniz.VERSION)

    for loop_times := 0; loop_times < 3; loop_times += 1 {
        p_cmp = make([]u8, cmp_len)
        p_uncomp = make([]u8, src_len)

        if p_cmp == nil || p_uncomp == nil {
            panic("Unable to allocate memory")
        }

        cmp_status = miniz.compress(&p_cmp[0], &cmp_len, strings.unsafe_string_to_cstring(g_str), src_len)
        if cmp_status != .OK {
            panic("compress() failed!")
        }

        fmt.printf("Compressed from %v to %v bytes\n", src_len, cmp_len)

        if step > 0 {
            n := u32(1 + (rand.uint32() % 3))
            for n > 0 {
                n -= 1

                i := u32(rand.uint64() % cmp_len)
                p_cmp[i] ~= u8(rand.uint32() % 0xFF)
            }
        }

        cmp_status = miniz.uncompress(&p_uncomp[0], &uncomp_len, strings.unsafe_string_to_cstring(string(p_cmp)), cmp_len)
        if cmp_status == .OK {
            total_succeeded += 1
        }

        if step > 0 {
            fmt.printf("Simple fuzzy test: step %v total_succeeded: %v\n", step, total_succeeded)
        } else {
            if cmp_status != .OK {
                panic("uncompress() failed!")
            }

            fmt.printf("Decompressed from %v to %v bytes\n", cmp_len, uncomp_len)

            if (uncomp_len != src_len) || mem.compare_ptrs(&p_uncomp[0], raw_data(g_str), int(src_len)) != 0 {
                panic("Decompression failure")
            }
        }

        delete(p_cmp)
        delete(p_uncomp)

        step += 1
    }

    fmt.print("Success")
}
