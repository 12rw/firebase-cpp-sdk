set(CMAKE_BUILD_TYPE Release)
set(FIREBASE_LINUX_USE_CXX11_ABI 0)
set(CMAKE_VERBOSE_MAKEFILE TRUE)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CLANG_TARGET_TRIPLE "x86_64-unknown-linux-gnu")

#toolchain
set(TOOLCHAIN_ROOT "/home/an/v20_clang-13.0.1-centos7/x86_64-unknown-linux-gnu")

#UE third party path
set(ENGINE_TP "/mnt/h/p4/pulsar/PulsarDev/Engine/Source/ThirdParty")

#bundled libc++
set(LIBCXX_ROOT "${ENGINE_TP}/Unix/LibCxx")
set(LIBCXX_INC "${LIBCXX_ROOT}/include/c++/v1")
set(LIBCXX_LIBDIR "${LIBCXX_ROOT}/lib/Unix/x86_64-unknown-linux-gnu")

set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${CLANG_TARGET_TRIPLE})
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_CXX_COMPILER_TARGET ${CLANG_TARGET_TRIPLE})
set(CMAKE_ASM_COMPILER clang)
set(CMAKE_ASM_COMPILER_TARGET ${CLANG_TARGET_TRIPLE})

set(CMAKE_C_FLAGS "" CACHE STRING "Flags for C compiler")
set(CMAKE_CXX_FLAGS "-I${LIBCXX_INC}" CACHE STRING "Flags for C++ compiler")
set(CMAKE_ASM_FLAGS "" CACHE STRING "Flags for ASM compiler")
set(CMAKE_EXE_LINKER_FLAGS "-nostdlib++ -L${LIBCXX_LIBDIR} -lc++ -lc++abi -fuse-ld=lld" CACHE STRING "Linker flags")

set(CMAKE_SYSROOT ${TOOLCHAIN_ROOT})
set(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

#use CACHE to also pass params to gRPC package
set(gRPC_SSL_PROVIDER "package" CACHE STRING "gRPC to use UE OpenSSL")
set(gRPC_ZLIB_PROVIDER "package" CACHE STRING "gRPC to use UE ZLIB")

#use OpenSSL from UE
set(OPENSSL_ROOT_DIR "${ENGINE_TP}/OpenSSL/1.1.1n" CACHE STRING "OpenSSL root")
set(OPENSSL_INCLUDE_DIR "${OPENSSL_ROOT_DIR}/include/Unix/x86_64-unknown-linux-gnu" CACHE STRING "OpenSSL include")
set(OPENSSL_CRYPTO_LIBRARY "${OPENSSL_ROOT_DIR}/lib/Unix/x86_64-unknown-linux-gnu/libcrypto.a" CACHE STRING "OpenSSL libcrypto")
set(OPENSSL_SSL_LIBRARY "${OPENSSL_ROOT_DIR}/lib/Unix/x86_64-unknown-linux-gnu/libssl.a" CACHE STRING "OpenSSL libssl")

#use ZLIB from UE
set(ZLIB_ROOT_DIR "${ENGINE_TP}/zlib/1.2.12" CACHE STRING "zlib root")
set(ZLIB_INCLUDE_DIR "${ZLIB_ROOT_DIR}/include" CACHE STRING "zlib include")
set(ZLIB_LIBRARY "${ZLIB_ROOT_DIR}/lib/Unix/x86_64-unknown-linux-gnu/Release/libz.a" CACHE STRING "zlib lib")

