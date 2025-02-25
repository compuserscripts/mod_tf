#!/bin/bash
set -euo pipefail

# Always use release mode
export VPC_NINJA_BUILD_MODE="release"

# Source the SDK container script from src directory
source src/sdk_container
run_in_sniper

solution_out="src/_vpc_/ninja/sdk_server_$VPC_NINJA_BUILD_MODE"

if [[ ! -e "$solution_out.ninja" ]]; then
    src/devtools/bin/vpc /hl2mp /tf /linux64 /ninja /define:SOURCESDK +dedicated /mksln "$solution_out"
    
    # Generate compile commands.
    ninja -f "$solution_out.ninja" -t compdb > src/compile_commands.json
    
    # Remove some unsupported clang commands.
    sed -i 's/-fpredictive-commoning//g; s/-fvar-tracking-assignments//g' src/compile_commands.json
    sed -i 's|/my_mod/src|.|g' src/compile_commands.json
    
    # Reflect changes done in compile_commands.json for easier diagnostics
    sed -i 's|-D_DLL_EXT=\.so|-D_DLL_EXT=_srv.so|g' src/compile_commands.json
    sed -i 's|-D_EXTERNAL_DLL_EXT=\.so|-D_EXTERNAL_DLL_EXT=_srv.so|g' src/compile_commands.json
    sed -i 's|server\.so|server_srv.so|g' src/compile_commands.json
    sed -i 's|lvstdlib|lvstdlib_srv|g' src/compile_commands.json
    sed -i 's|ltier0|ltier0_srv|g' src/compile_commands.json
    
    sed -i 's|-D_DLL_EXT=\.so|-D_DLL_EXT=_srv.so|g' "$solution_out.ninja"
    sed -i 's|-D_EXTERNAL_DLL_EXT=\.so|-D_EXTERNAL_DLL_EXT=_srv.so|g' "$solution_out.ninja"
    sed -i 's|server\.so|server_srv.so|g' "$solution_out.ninja"
    sed -i 's|libtier0\.so|libtier0_srv.so|g' "$solution_out.ninja"
    sed -i 's|libvstdlib\.so|libvstdlib_srv.so|g' "$solution_out.ninja"
    sed -i 's|lvstdlib|lvstdlib_srv|g' "$solution_out.ninja"
    sed -i 's|ltier0|ltier0_srv|g' "$solution_out.ninja"
fi

# Build using all available processors
ninja -f "$solution_out.ninja" -j$(nproc)

echo "Server build complete in release mode!"
