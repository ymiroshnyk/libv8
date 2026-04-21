#!/bin/sh

set -e

dir="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "${dir}/v8" ]; then
  echo "v8 not found"
  exit 1
fi

# Detect pointer compression from GN args
os="$(sh "${dir}/scripts/get_os.sh")"
extra_defines=""
if grep -q "v8_enable_pointer_compression=true" "${dir}/args/${os}.gn" 2>/dev/null; then
  extra_defines="-DV8_COMPRESS_POINTERS -DV8_31BIT_SMIS_ON_64BIT_ARCH"
fi

(
  set -x
  g++ -I"${dir}/v8" -I"${dir}/v8/include" \
    ${extra_defines} \
    "${dir}/v8/samples/hello-world.cc" -o hello_world \
    -lv8_monolith -L"${dir}/v8/out/release/obj/" \
    -pthread -std=c++20 -ldl
)

sh -c "./hello_world"
