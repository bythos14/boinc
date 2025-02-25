#!/bin/bash

# This file is part of BOINC.
# http://boinc.berkeley.edu
# Copyright (C) 2023 University of California
#
# BOINC is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# BOINC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with BOINC.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Script to build the wxMac-3.1.6 wxCocoa library for BOINC
#
# by Charlie Fenton    7/21/06
# Updated for wx-Mac 2.8.10 and Unicode 4/17/09
# Updated for OS 10.7 and XCode 4.1 with OS 10.4 compatibility 9/26/11
# Updated for partial OS 10.8 and XCode 4.5 compatibility 7/27/12
# Updated for wxCocoa 2.9.5 8/20/13
# Updated for wxCocoa 3.0.0 11/12/13
# Fix for wxCocoa 3.0.0 2/13/14
# Patch to fix crash on OS 10.5 or 10.6 when built on OS 10.7+ 2/18/14
# Enable wxWidgets asserts in Release build 3/6/14
# Disable all wxWidgets debug support in Release build (revert 3/6/14 change) 5/29/14
# Fix wxListCtrl flicker when resizing columns in wxCocoa 3.0.0 6/13/14
# Revise fix for wxListCtrl flicker to match the fix in wxWidgets trunk 6/19/14
# Build 64-bit library (temporarily build both 32-bit and 64-bit libraries) 10/22/17
# Update for wxCocoa 3.1.0 10/25/17
# Build only 64-bit library 1/25/18
# Fix wxWidgets 3.1.0 bug when wxStaticBox has no label 3/20/18
# Fix wxWidgets 3.1.0 to not use backingScaleFactor API on OS 10.6 6/8/18
# Update for compatibility with Xcode 10 (this script for BOINC 7.15+ only) 10/14/18
# Add patches to build with Xcode 11 and OS 10.15 sdk 3/1/20
# Updated 8/4/20 TO build Apple Silicon / arm64 and x86_64 Universal binary
# Updated 5/18/21 for compatibility with zsh
# Updated 9/30/21 for wxCocoa 3.1.5
# Updated 10/18/21 to add -Werror=unguarded-availability compiler flag
# Updated 2/6/23 changed MACOSX_DEPLOYMENT_TARGET to 10.13
# Updated 4/6/23 for wxCocoa 3.1.6 and for args now accepted by patch utility
#
## This script requires OS 10.6 or later
##
## In Terminal, CD to the wxWidgets-3.1.6 directory.
##    cd [path]/wxWidgets-3.1.6/
## then run this script:
##    source [ path_to_this_script ] [ -clean ] [ -nodebug ] [--prefix PATH]
##
## the -clean argument will force a full rebuild.
## the -nodebug argument will omit building the debug version of the library
## if --prefix is given as absolute path the library is installed into there
## use -q or --quiet to redirect build output to /dev/null instead of /dev/stdout
#

SRCDIR=$PWD
echo "${SRCDIR}" | grep " " > /dev/null 2>&1
if [ "$?" -eq "0" ]; then
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********                                      **********"
    echo "********** ERROR: Path must not contain spaces! **********"
    echo "**********                                      **********"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    return 1
fi

echo ""

## Add our custom method SetItemBitmap(unsigned int n, const wxBitmap& bitmap)
## to wxChoice. We use this to create our own custom CBOINCBitmapComboBox
## which uses native Mac controls instead of wxBitmapComboBox which does not.
## By using only native Mac controls in BOINC SImple View, MacOS will provide
## accessibility support automatically.
##
## We patch 4 files to accomplish this.
##
# Patch wxWidgets-3.1.6/include/wx/osx/choice.h
if [ ! -f include/wx/osx/choice.h.orig ]; then
    cat >> /tmp/choice_h_diff << ENDOFFILE
--- include/wx/osx/choice.h
+++ include/wx/osx/choice_patched.h
@@ -73,6 +73,7 @@
     virtual int FindString(const wxString& s, bool bCase = false) const wxOVERRIDE;
     virtual wxString GetString(unsigned int n) const wxOVERRIDE;
     virtual void SetString(unsigned int pos, const wxString& s) wxOVERRIDE;
+    void SetItemBitmap(unsigned int n, const wxBitmap& bitmap);
     // osx specific event handling common for all osx-ports

     virtual bool OSXHandleClicked(double timestampsec) wxOVERRIDE;
ENDOFFILE
    patch -b -f -i /tmp/choice_h_diff include/wx/osx/choice.h
    rm -f /tmp/choice_h_diff
else
    echo "include/wx/osx/choice.h already patched"
fi

echo ""

# Patch wxWidgets-3.1.6/src/osx/choice_osx.cpp
if [ ! -f src/osx/choice_osx.cpp.orig ]; then
    cat >> /tmp/choice_osx_cpp_diff << ENDOFFILE
--- src/osx/choice_osx.cpp    2021-04-12 15:23:58.000000000 -0700
+++ src/osx/choice_osx_patched.cpp    2021-09-30 00:26:06.000000000 -0700
@@ -217,6 +217,13 @@
     return m_strings[n] ;
 }

+void wxChoice::SetItemBitmap(unsigned int n, const wxBitmap& bitmap)
+{
+    wxCHECK_RET( IsValid(n), wxT("wxChoice::SetItemBitmap(): invalid index") );
+
+    dynamic_cast<wxChoiceWidgetImpl*>(GetPeer())->SetItemBitmap(n, bitmap);
+}
+
 // ----------------------------------------------------------------------------
 // client data
 // ----------------------------------------------------------------------------
ENDOFFILE
    patch -b -f -i /tmp/choice_osx_cpp_diff src/osx/choice_osx.cpp
    rm -f /tmp/choice_osx_cpp_diff
else
    echo "src/osx/choice_osx.cpp already patched"
fi

echo ""

# Patch wxWidgets-3.1.6/include/wx/osx/core/private.h
if [ ! -f include/wx/osx/core/private.h.orig ]; then
    cat >> /tmp/private_h_cpp_diff << ENDOFFILE
--- include/wx/osx/core/private.h    2021-04-12 15:23:58.000000000 -0700
+++ include/wx/osx/core/private_patched.h    2021-09-30 01:11:28.000000000 -0700
@@ -821,6 +821,8 @@
     }

     virtual void SetItem(int pos, const wxString& item) = 0;
+
+    virtual void SetItemBitmap(unsigned int n, const wxBitmap& bitmap) = 0;
 };


ENDOFFILE
    patch -b -f -i /tmp/private_h_cpp_diff include/wx/osx/core/private.h
    rm -f /tmp/private_h_cpp_diff
else
    echo "include/wx/osx/core/private.h already patched"
fi

echo ""

# Patch wxWidgets-3.1.6/src/osx/cocoa/choice.mm
if [ ! -f src/osx/cocoa/choice.mm.orig ]; then
    cat >> /tmp/choice_mm_diff << ENDOFFILE
--- src/osx/cocoa/choice.mm    2021-09-28 22:52:32.000000000 -0700
+++ src/osx/cocoa/choice_patched.mm    2021-09-30 01:08:32.000000000 -0700
@@ -130,6 +130,15 @@
         m_popUpMenu->FindItemByPosition( pos )->SetItemLabel( s ) ;
     }

+    void SetItemBitmap(unsigned int n, const wxBitmap& bitmap) wxOVERRIDE
+    {
+        if ( bitmap.Ok() ) {
+            wxMenuItem *item = m_popUpMenu->FindItemByPosition( n );
+            item->SetBitmap( bitmap );
+            item->UpdateItemBitmap();
+        }
+    }
+
 private:
     wxMenu* m_popUpMenu;
 };
ENDOFFILE
    patch -b -f -i /tmp/choice_mm_diff src/osx/cocoa/choice.mm
    rm -f /tmp/choice_mm_diff
else
    echo "src/osx/cocoa/choice.mm already patched"
fi

echo ""

##***********************************************************
##*************** End of patches section ********************
##***********************************************************

doclean=""
stdout_target="/dev/stdout"
lprefix=""
libPathRel="build/osx/build/Release"
libPathDbg="build/osx/build/Debug"
nodebug=""
beautifier="cat" # we need a fallback if xcpretty is not available
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -clean|--clean)
        doclean="clean"
        ;;
        -nodebug|--nodebug)
        nodebug="yes"
        ;;
        -prefix|--prefix)
        lprefix="$2"
        libPathRel="${lprefix}/lib"
        libPathDbg="${lprefix}/lib/debug"
        shift
        ;;
        -q|--quiet)
        stdout_target="/dev/null"
        ;;
    esac
    shift # past argument or value
done

XCPRETTYPATH=`xcrun -find xcpretty 2>/dev/null`
if [ $? -eq 0 ]; then
    beautifier="xcpretty"
fi

retval=0
alreadyBuilt=0

# First run wxWidget's built-in script to copy setup.h into place
cd build/osx || return 1
../../distrib/mac/pbsetup-sh ../../src ../../build/osx/setup/cocoa
cd ../.. || return 1

if [ "${doclean}" != "clean" ] && [ -f "${libPathRel}/libwx_osx_cocoa_static.a" ]; then
    GCCPATH=`xcrun -find gcc`
    if [ $? -ne 0 ]; then
        echo "ERROR: can't find gcc compiler"
        return 1
    fi

    alreadyBuilt=1
    GCC_can_build_x86_64="no"
    GCC_can_build_arm64="no"

    GCC_archs=`lipo -archs "${GCCPATH}"`
    if [[ "${GCC_archs}" = *"x86_64"* ]]; then GCC_can_build_x86_64="yes"; fi
    if [[ "${GCC_archs}" = *"arm64"* ]]; then GCC_can_build_arm64="yes"; fi
    if [ $GCC_can_build_x86_64 = "yes" ]; then
        lipo "${libPathRel}/libwx_osx_cocoa_static.a" -verify_arch x86_64
        if [ $? -ne 0 ]; then alreadyBuilt=0; doclean="clean"; fi
    fi

    if [ $alreadyBuilt -eq 1 ] && [ $GCC_can_build_arm64 = "yes" ]; then
        lipo "${libPathRel}/libwx_osx_cocoa_static.a" -verify_arch arm64
        if [ $? -ne 0 ]; then alreadyBuilt=0; doclean="clean"; fi
    fi
fi

if [ $alreadyBuilt -eq 1 ]; then
    cwd=$(pwd)
    dirname=${cwd##*/}
    echo "${dirname} Release libwx_osx_cocoa_static.a already built"
    echo ""
else
    ## We must override some of the build settings in wxWindows.xcodeproj
    ## For wxWidgets 3.0.0 through 3.1.0 (at least) we must use legacy WebKit APIs
    ## for x86_64, so we must define WK_API_ENABLED=0

    ## "-include unistd.h" is a workaround for a problem under Xcode 12 Beta
    ## $(ARCHS_STANDARD) builds Universal Binary (x86_64 & arm64) library under
    ## Xcode versions that can, otherwise it builds only the X86_64 library.

    ## The "-Werror=unguarded-availability" compiler flag generates an error if
    ## there is an unguarded API not available in our Deployment Target. This
    ## helps ensure wxWidgets won't try to use unavailable APIs on older Mac
    ## systems supported by BOINC.

    set -o pipefail
     xcodebuild -project build/osx/wxcocoa.xcodeproj -target static -configuration Release $doclean build ARCHS="\$(ARCHS_STANDARD)" ONLY_ACTIVE_ARCH="NO" MACOSX_DEPLOYMENT_TARGET="10.13" GCC_C_LANGUAE_STANDARD="compiler-default" CLANG_CXX_LANGUAGE_STANDARD="compiler-default" CLANG_CXX_LIBRARY="libc++" OTHER_CFLAGS="-Wall -Wundef -Werror=unguarded-availability -fno-strict-aliasing -fno-common -DHAVE_LOCALTIME_R=1 -DHAVE_GMTIME_R=1 -DwxUSE_UNICODE=1 -DwxDEBUG_LEVEL=0 -DPNG_ARM_NEON_OPT=0 -DNDEBUG -fvisibility=hidden" OTHER_CPLUSPLUSFLAGS="-Wall -Wundef -Werror=unguarded-availability -fno-strict-aliasing -fno-common -DHAVE_LOCALTIME_R=1 -DHAVE_GMTIME_R=1 -DwxUSE_UNICODE=1 -DwxDEBUG_LEVEL=0 -DPNG_ARM_NEON_OPT=0 -DNDEBUG -fvisibility=hidden -fvisibility-inlines-hidden" GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) wxUSE_UNICODE_UTF8=1  wxUSE_UNICODE_WCHAR=0 __ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORES=1" | $beautifier; retval=$?
    if [ ${retval} -ne 0 ]; then return 1; fi
    if [ "x${lprefix}" != "x" ]; then
        # copy library and headers to $lprefix
        mkdir -p "${libPathRel}"
        mkdir -p "${lprefix}/include"
        cp build/osx/build/Release/libwx_osx_cocoa_static.a "${libPathRel}"
        strip -x "${libPathRel}/libwx_osx_cocoa_static.a"
        cp -R include/wx "${lprefix}/include"
        cp build/osx/setup/cocoa/include/wx/setup.h "${lprefix}/include/wx"
    fi
fi

if [ "${nodebug}" = "yes" ]; then
    return 0
fi

alreadyBuilt=0
if [ "${doclean}" != "clean" ] && [ -f "${libPathDbg}/libwx_osx_cocoa_static.a" ]; then
    alreadyBuilt=1
    GCC_can_build_x86_64="no"
    GCC_can_build_arm64="no"

    GCC_archs=`lipo -archs "${GCCPATH}"`
    if [[ "${GCC_archs}" = *"x86_64"* ]]; then GCC_can_build_x86_64="yes"; fi
    if [[ "${GCC_archs}" = *"arm64"* ]]; then GCC_can_build_arm64="yes"; fi
    if [ GCC_can_build_x86_64 = "yes" ]; then
        lipo "${libPathDbg}/libwx_osx_cocoa_static.a" -verify_arch x86_64
        if [ $? -ne 0 ]; then alreadyBuilt=0; doclean="clean"; fi
    fi

    if [ $alreadyBuilt -eq 1 ] && [ GCC_can_build_arm64 = "yes" ]; then
        lipo "${libPathDbg}/libwx_osx_cocoa_static.a" -verify_arch arm64
        if [ $? -ne 0 ]; then alreadyBuilt=0; doclean="clean"; fi
    fi
fi

if [ $alreadyBuilt -eq 1 ]; then
    cwd=$(pwd)
    dirname=${cwd##*/}
    echo "${dirname} Debug libwx_osx_cocoa_static.a already built"
    echo ""
else
    ## We must override some of the build settings in wxWindows.xcodeproj
    ## For wxWidgets 3.0.0 through 3.1.0 (at least) we must use legacy WebKit APIs
    ## for x86_64, so we must define WK_API_ENABLED=0
    ##
    ## We don't use $doclean here because:
    ## * As of Xcode 10, "clean" would delete both the Release and Debug builds, and
    ## * If there is a previous build of wrong architecture, both Xcode 10 and
    ## earlier versions of Xcode correctly overwrite it with x86_64-only build.
    ##
    ## "-include unistd.h" is a workaround for a problem under Xcode 12 Beta
    ## $(ARCHS_STANDARD) builds Universal Binary (x86_64 & arm64) library under
    ## Xcode versions that can, otherwise it builds only the X86_64 library.
    set -o pipefail
   xcodebuild -project build/osx/wxcocoa.xcodeproj -target static -configuration Debug build ARCHS="\$(ARCHS_STANDARD)" ONLY_ACTIVE_ARCH="NO" MACOSX_DEPLOYMENT_TARGET="10.13" GCC_C_LANGUAE_STANDARD="compiler-default" CLANG_CXX_LANGUAGE_STANDARD="compiler-default" CLANG_CXX_LIBRARY="libc++" OTHER_CFLAGS="-Wall -Wundef -Werror=unguarded-availability -fno-strict-aliasing -fno-common -DHAVE_LOCALTIME_R=1 -DHAVE_GMTIME_R=1 -DwxUSE_UNICODE=1  -DPNG_ARM_NEON_OPT=0 -DDEBUG -fvisibility=hidden" OTHER_CPLUSPLUSFLAGS="-Wall -Wundef -Werror=unguarded-availability -fno-strict-aliasing -fno-common -DHAVE_LOCALTIME_R=1 -DHAVE_GMTIME_R=1 -DwxUSE_UNICODE=1 -DPNG_ARM_NEON_OPT=0 -DDEBUG -fvisibility=hidden -fvisibility-inlines-hidden" GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) wxUSE_UNICODE_UTF8=1  wxUSE_UNICODE_WCHAR=0 __ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORES=1" | $beautifier; retval=$?
    if [ ${retval} -ne 0 ]; then return 1; fi
    if [ "x${lprefix}" != "x" ]; then
        # copy debug library to $PREFIX
        mkdir -p "${libPathDbg}"
        cp build/osx/build/Debug/libwx_osx_cocoa_static.a "${libPathDbg}"
    fi
fi
return 0
