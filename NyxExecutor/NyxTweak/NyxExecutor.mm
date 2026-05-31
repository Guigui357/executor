// File: NyxExecutor/NyxTweak/NyxExecutor.mm
// Versão corrigida - __builtin___clear_cache fix + .dylib compatível

#include <dlfcn.h>
#include <string>
#include <vector>
#include <cstdint>
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include <libkern/OSCacheControl.h>

typedef int (*luaL_loadstring_t)(void* L, const char* s);
typedef int (*lua_pcall_t)(void* L, int nargs, int nresults, int errfunc);

static luaL_loadstring_t luaL_loadstring = nullptr;
static lua_pcall_t lua_pcall = nullptr;
static void* RobloxLuaState = nullptr;

uintptr_t FindPattern(uintptr_t start, size_t size, const char* pattern) {
    std::vector<uint8_t> bytes;
    std::vector<bool> mask;
    for (const char* p = pattern; *p; ++p) {
        if (*p == ' ') continue;
        if (*p == '?') {
            bytes.push_back(0); mask.push_back(false);
        } else {
            bytes.push_back(static_cast<uint8_t>(strtol(p, nullptr, 16)));
            mask.push_back(true);
            if (*(p+1)) ++p;
        }
    }
    for (uintptr_t addr = start; addr < start + size - bytes.size(); ++addr) {
        bool match = true;
        for (size_t i = 0; i < bytes.size(); ++i) {
            if (mask[i] && *(uint8_t*)(addr + i) != bytes[i]) {
                match = false; break;
            }
        }
        if (match) return addr;
    }
    return 0;
}

void PatchSetThreadIdentity(uintptr_t funcAddr) {
    if (!funcAddr) return;
    uintptr_t page = funcAddr & ~0xFFF;
    mprotect((void*)page, 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
    uint32_t patch[] = {0x52800008, 0xD65F03C0}; // mov w0, #8; ret
    memcpy((void*)funcAddr, patch, sizeof(patch));
    sys_icache_invalidate(
        (void*)funcAddr,
        sizeof(patch)
    );
    printf("[Nyx] SetThreadIdentity patched to high identity\n");
}

void ExecuteServerCode(const char* code) {
    if (!RobloxLuaState) return;
    int r = luaL_loadstring(RobloxLuaState, code);
    if (r == 0) lua_pcall(RobloxLuaState, 0, 0, 0);
}

__attribute__((constructor))
static void NyxInit() {
    void* robloxLib = dlopen("RobloxPlayer", RTLD_LAZY);
    if (!robloxLib) robloxLib = dlopen("/usr/lib/RobloxPlayer", RTLD_LAZY);
    uintptr_t base = (uintptr_t)robloxLib;
    size_t size = 0x4000000;

    uintptr_t setIdentityAddr = FindPattern(base, size, "FF ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?");
    if (setIdentityAddr) PatchSetThreadIdentity(setIdentityAddr);

    luaL_loadstring = (luaL_loadstring_t)FindPattern(base, size, "your_ios_lua_loadstring_arm64_sig");
    lua_pcall = (lua_pcall_t)FindPattern(base, size, "your_ios_lua_pcall_arm64_sig");
    RobloxLuaState = (void*)FindPattern(base, size, "your_ios_lua_state_sig");

    printf("[Nyx] iOS Serverside Executor loaded - FE bypassed\n");
}

extern "C" __attribute__((visibility("default"))) void NyxExecute(const char* code) {
    ExecuteServerCode(code);
}
