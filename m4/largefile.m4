# Enable large files on systems where this is not the default.
# Enable support for files on Linux file systems with 64-bit inode numbers.

# Copyright 1992-1996, 1998-2023 Free Software Foundation, Inc.
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# The following macro works around a problem in Autoconf's AC_FUNC_FSEEKO:
# It does not set _LARGEFILE_SOURCE=1 on HP-UX/ia64 32-bit, although this
# setting of _LARGEFILE_SOURCE is needed so that <stdio.h> declares fseeko
# and ftello in C++ mode as well.
AC_DEFUN([gl_SET_LARGEFILE_SOURCE],
[
  AC_REQUIRE([AC_CANONICAL_HOST])
  AC_FUNC_FSEEKO
  case "$host_os" in
    hpux*)
      AC_DEFINE([_LARGEFILE_SOURCE], [1],
        [Define to 1 to make fseeko visible on some hosts (e.g. glibc 2.2).])
      ;;
  esac
])

# Work around a problem in Autoconf through at least 2.71 on glibc 2.34+
# with _TIME_BITS.  Also, work around a problem in autoconf <= 2.69:
# AC_SYS_LARGEFILE does not configure for large inodes on Mac OS X 10.5,
# or configures them incorrectly in some cases.
m4_version_prereq([2.70], [], [

# _AC_SYS_LARGEFILE_TEST_INCLUDES
# -------------------------------
m4_define([_AC_SYS_LARGEFILE_TEST_INCLUDES],
[#include <sys/types.h>
 /* Check that off_t can represent 2**63 - 1 correctly.
    We can't simply define LARGE_OFF_T to be 9223372036854775807,
    since some C++ compilers masquerading as C compilers
    incorrectly reject 9223372036854775807.  */
#define LARGE_OFF_T (((off_t) 1 << 31 << 31) - 1 + ((off_t) 1 << 31 << 31))
  int off_t_is_large[[(LARGE_OFF_T % 2147483629 == 721
                       && LARGE_OFF_T % 2147483647 == 1)
                      ? 1 : -1]];[]dnl
])
])# m4_version_prereq 2.70


# _AC_SYS_LARGEFILE_MACRO_VALUE(C-MACRO, VALUE,
#                               CACHE-VAR,
#                               DESCRIPTION,
#                               PROLOGUE, [FUNCTION-BODY])
# --------------------------------------------------------
m4_define([_AC_SYS_LARGEFILE_MACRO_VALUE],
[AC_CACHE_CHECK([for $1 value needed for large files], [$3],
[while :; do
  m4_ifval([$6], [AC_LINK_IFELSE], [AC_COMPILE_IFELSE])(
    [AC_LANG_PROGRAM([$5], [$6])],
    [$3=no; break])
  m4_ifval([$6], [AC_LINK_IFELSE], [AC_COMPILE_IFELSE])(
    [AC_LANG_PROGRAM([#undef $1
#define $1 $2
$5], [$6])],
    [$3=$2; break])
  $3=unknown
  break
done])
case $$3 in #(
  no | unknown) ;;
  *) AC_DEFINE_UNQUOTED([$1], [$$3], [$4]);;
esac
rm -rf conftest*[]dnl
])# _AC_SYS_LARGEFILE_MACRO_VALUE


# AC_SYS_LARGEFILE
# ----------------
# By default, many hosts won't let programs access large files;
# one must use special compiler options to get large-file access to work.
# For more details about this brain damage please see:
# http://www.unix.org/version2/whatsnew/lfs20mar.html
# Additionally, on Linux file systems with 64-bit inodes a file that happens
# to have a 64-bit inode number cannot be accessed by 32-bit applications on
# Linux x86/x86_64.  This can occur with file systems such as XFS and NFS.
AC_DEFUN([AC_SYS_LARGEFILE],
[AC_ARG_ENABLE(largefile,
               [  --disable-largefile     omit support for large files])
AS_IF([test "$enable_largefile" != no],
 [AC_CACHE_CHECK([for special C compiler options needed for large files],
    ac_cv_sys_largefile_CC,
    [ac_cv_sys_largefile_CC=no
     if test "$GCC" != yes; then
       ac_save_CC=$CC
       while :; do
         # IRIX 6.2 and later do not support large files by default,
         # so use the C compiler's -n32 option if that helps.
         AC_LANG_CONFTEST([AC_LANG_PROGRAM([_AC_SYS_LARGEFILE_TEST_INCLUDES])])
         AC_COMPILE_IFELSE([], [break])
         CC="$CC -n32"
         AC_COMPILE_IFELSE([], [ac_cv_sys_largefile_CC=' -n32'; break])
         break
       done
       CC=$ac_save_CC
       rm -f conftest.$ac_ext
    fi])
  if test "$ac_cv_sys_largefile_CC" != no; then
    CC=$CC$ac_cv_sys_largefile_CC
  fi

  _AC_SYS_LARGEFILE_MACRO_VALUE(_FILE_OFFSET_BITS, 64,
    ac_cv_sys_file_offset_bits,
    [Number of bits in a file offset, on hosts where this is settable.],
    [_AC_SYS_LARGEFILE_TEST_INCLUDES])
  AS_CASE([$ac_cv_sys_file_offset_bits],
    [unknown],
      [_AC_SYS_LARGEFILE_MACRO_VALUE([_LARGE_FILES], [1],
         [ac_cv_sys_large_files],
         [Define for large files, on AIX-style hosts.],
         [_AC_SYS_LARGEFILE_TEST_INCLUDES])],
    [64],
      [gl_YEAR2038_BODY([])])])
])# AC_SYS_LARGEFILE

# Enable large files on systems where this is implemented by Gnulib, not by the
# system headers.
# Set the variables WINDOWS_64_BIT_OFF_T, WINDOWS_64_BIT_ST_SIZE if Gnulib
# overrides ensure that off_t or 'struct size.st_size' are 64-bit, respectively.
AC_DEFUN([gl_LARGEFILE],
[
  AC_REQUIRE([AC_CANONICAL_HOST])
  case "$host_os" in
    mingw*)
      dnl Native Windows.
      dnl mingw64 defines off_t to a 64-bit type already, if
      dnl _FILE_OFFSET_BITS=64, which is ensured by AC_SYS_LARGEFILE.
      AC_CACHE_CHECK([for 64-bit off_t], [gl_cv_type_off_t_64],
        [AC_COMPILE_IFELSE(
           [AC_LANG_PROGRAM(
              [[#include <sys/types.h>
                int verify_off_t_size[sizeof (off_t) >= 8 ? 1 : -1];
              ]],
              [[]])],
           [gl_cv_type_off_t_64=yes], [gl_cv_type_off_t_64=no])
        ])
      if test $gl_cv_type_off_t_64 = no; then
        WINDOWS_64_BIT_OFF_T=1
      else
        WINDOWS_64_BIT_OFF_T=0
      fi
      dnl Some mingw versions define, if _FILE_OFFSET_BITS=64, 'struct stat'
      dnl to 'struct _stat32i64' or 'struct _stat64' (depending on
      dnl _USE_32BIT_TIME_T), which has a 32-bit st_size member.
      AC_CACHE_CHECK([for 64-bit st_size], [gl_cv_member_st_size_64],
        [AC_COMPILE_IFELSE(
           [AC_LANG_PROGRAM(
              [[#include <sys/types.h>
                struct stat buf;
                int verify_st_size_size[sizeof (buf.st_size) >= 8 ? 1 : -1];
              ]],
              [[]])],
           [gl_cv_member_st_size_64=yes], [gl_cv_member_st_size_64=no])
        ])
      if test $gl_cv_member_st_size_64 = no; then
        WINDOWS_64_BIT_ST_SIZE=1
      else
        WINDOWS_64_BIT_ST_SIZE=0
      fi
      ;;
    *)
      dnl Nothing to do on gnulib's side.
      dnl A 64-bit off_t is
      dnl   - already the default on Mac OS X, FreeBSD, NetBSD, OpenBSD, IRIX,
      dnl     OSF/1, Cygwin,
      dnl   - enabled by _FILE_OFFSET_BITS=64 (ensured by AC_SYS_LARGEFILE) on
      dnl     glibc, HP-UX, Solaris,
      dnl   - enabled by _LARGE_FILES=1 (ensured by AC_SYS_LARGEFILE) on AIX,
      dnl   - impossible to achieve on Minix 3.1.8.
      WINDOWS_64_BIT_OFF_T=0
      WINDOWS_64_BIT_ST_SIZE=0
      ;;
  esac
])
