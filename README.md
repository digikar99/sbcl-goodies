# SBCL Goodies

The current [`all` branch of this
repository](https://github.com/digikar99/sbcl-goodies/tree/all) contains Github
Actions workflows and build scripts that build each SBCL release with
OpenSSL. It is a derivative of
[sionescu/sbcl-goodies](https://github.com/sionescu/sbcl-goodies) adapted for
both MacOS and Windows. The
[Releases](https://github.com/digikar99/sbcl-goodies-all/releases) contains

| OS \ Arch | x86-64 | arm64 |
|-----------|--------|-------|
| Linux     | Yes    | Yes   |
| MacOS     | Yes    | Yes   |
| Windows   | Yes    | -     |

For Windows, in contrast to the Linux (or Posix?) variant built at
sionescu/sbcl-goodies, we have the following modifications:

- libfixposix and libtls is skipped; only `libssl libcrypto` are linked
- sbcl available from msys2 pacman is used as the host
- `--fancy --with-sb-linkable-runtime` build options are used

sbcl-goodies builds each SBCL release with a few extra "goodies" statically
linked into the SBCL runtime: OpenSSL and libfixposix. These two libraries are
often cited as a reason why distributing Common Lisp binaries is difficult, so
it's useful to have them built into the core.

## Modifications

 - `src/runtime/sbcl` is statically linked to `libzstd`, `libcrypto`, `libssl`,
   `libtls` and `libfixposix`
 - in the SBCL core, a new keyword was added to `*features*`:
   `:CL+SSL-FOREIGN-LIBS-ALREADY-LOADED`
 - `CL:LISP-IMPLEMENTATION-VERSION` returns a string containing the revision,
   e.g. `"2.3.1+r00"`
 - the subdirectory `third_party/include` contains the headers of libfixposix

