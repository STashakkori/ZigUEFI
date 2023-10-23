const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;
const alloc = @import("std").heap;

pub fn main() void {
    const boot_services = uefi.system_table.boot_services.?;

    var con_out = uefi.system_table.con_out.?;
    var buf: [40]u8 = undefined;

    var buffer_size: usize = 2;
    var name: [*]align(8) u8 = undefined;
    _ = boot_services.allocatePool(uefi.tables.MemoryType.BootServicesData, buffer_size * @sizeOf(u16), @alignCast(&name));
    name[0] = 0;
    var guid: uefi.Guid = undefined;
    while (true) {
        var name_size: usize = buffer_size;
        switch (uefi.system_table.runtime_services.getNextVariableName(&name_size, @as(*[1]u16, @alignCast(name)), &guid)) {
            uefi.Status.Success => {
                var message_utf8: [40]u8 = undefined;
                var char_index: usize = 0;
                for (name[0 .. name_size]) |char| {
                    if (char_index < message_utf8.len) {
                        message_utf8[char_index] = u8(char);
                        char_index += 1;
                    }
                }
                buf = message_utf8;
                _ = con_out.outputString(message_utf8);
            },
            uefi.Status.BufferTooSmall => {
                var alloc_name: [*]align(8) u16 = undefined;
                _ = boot_services.allocatePool(uefi.tables.MemoryType.BootServicesData, name_size, @alignCast(&alloc_name));
                alloc_name = alloc.concat(alloc_name, @alignCast(name));
                _ = boot_services.freePool(@alignCast(name));
                name = alloc_name;
                buffer_size = name_size;
            },
            uefi.Status.NotFound => break,
            else => {
                break;
            },
        }
    }

    _ = boot_services.freePool(@alignCast(name));
    _ = boot_services.stall(10 * 1000 * 1000);
}
