#!/bin/bash
iokit_md5_current="$(md5 -q /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit)"
nvda_md5_current="$(md5 -q /System/Library/Extensions/NVDAGK100Hal.kext/Contents/MacOS/NVDAGK100Hal)"
amd_md5_current="$(md5 -q /System/Library/Extensions/AMDSupport.kext/Contents/MacOS/AMDSupport)"

iokit_md5_10_7_4=b1e6fb797d7d3470acabe7c06e6c139e
iokit_md5_10_7_5=0176a6d9a7c3b8c39bb06785fcdfca6d
iokit_md5_10_8_3=9bf853999cff6ee4158d3fa2acc0ce7c
iokit_md5_10_8_4=233a4256b845b647b151739c87070695
iokit_md5_10_8_5_12F45=5d69bf9227997dfad5e48fa87bd14598
iokit_md5_10_9_1=d085445f30410008593a65ef4b5f9889
iokit_md5_10_9_2=9804392bbe8ba4b589175be56889c6c7

iokit_md5_10_7_4_patched=92eb38917f6ec4f341bff6fd1b6076ed
iokit_md5_10_7_5_patched=b5b15d1ed5a404962bc7de895a0df56a
iokit_md5_10_8_3_patched=289039239535c91146518c64aea5907b
iokit_md5_10_8_4_patched=8c70a0ca62bf65e9ffa8667e2871c287
iokit_md5_10_8_5_12F45_patched=de3ad8279077c675ae8093193deb253f
iokit_md5_10_9_1_patched=0962001659a2031c2425206d9239bda4
iokit_md5_10_9_2_patched=45d8fc0e1210f0672297a7716478990e

nvda_md5_10_8_3=6a2d5017b6ddd3d19de2f4039d4c88ec
nvda_md5_10_8_4=b553fd25b25d2262317e9de758888d2b
nvda_md5_10_8_5_12F45=f84d891f1a67aa278453be59a6e1fece
nvda_md5_10_9_1=6de28959ec948513c239b1bf31205465

nvda_md5_10_8_3_patched=7e8372fca35c5e7db90a229e70709d58
nvda_md5_10_8_4_patched=3c552ba24fa89b2ea892dd711088e8d5
nvda_md5_10_8_5_12F45_patched=5e65da83006468e8a69ef60a180ea08d
nvda_md5_10_9_1_patched=bbb0885323ea3221150839782fbd553f

amd_md5_10_9_1=693bffd29de3e5af0f49ae02f9d6a319

amd_md5_10_9_1_patched=874caed6a4abf8e596e43400a624ca79

# Instructions for how to reproduce the IOKit patch on a newer version of the
# binary:
#
# First, take the md5 hash of IOKit for storing in this file
# md5 -q /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
#
# For OS X 10.9.2, the result is
# 9804392bbe8ba4b589175be56889c6c7
#
# copy IOKit local and disassemble it
# cp /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit .
# otool -vt IOKit > IOKit.asm
#
# Open up that file and look for the function _CheckTimingWithRange.  You can
# tell because the line begins with the function name and ends in a colon:
# _CheckTimingWithRange:
#
# Find the very first jump instruction in the function. In this case it is
# labelled JNE, which means jump if not equal.  The instruction before is
# a comparison, and a literal translation to C would be expressed as:
# if(value1 != value2) goto result;
#
# Now we look at the address it's jumping to.  In this case it's 0x17341
#
# Go down to that instruction, and you’ll see that there’s a gap between the
# last jump instruction before it and this block.  That block is the cleanup
# section that returns a good response.  This function is structured such that
# error cases and success share the same return block, with a success block
# just before the return block.
#
# We want to patch this function so that it always returns a good response,
# which means changing the first instruction to jump to the good block, which is
# the first instruction to follow the very last jump to 0x17341.  The address
# of this block is 0x17327
#
# Jump instructions in this code are relative, se we need to calculate the
# offset being used by the current instruction, and also the address that will
# be used by the replacement instruction.
#
# Relative jump instructions are stored as an offset to the following
# instruction. So, in the case of the following code block:
# Address
#       1  JMP to 3
#       2  Do Nothing
#       3  Do Something
#
# The jump instruction would be encoded as 'Jump +1', since 2 is the address of
# the next instruction.  This is because the processor automatically adds the
# distance to the next instruction with each instruction run, so it will be
# included into the starting calculation.
#
# For the existing code, we have the following information:
# Instruction:                  JNE 0x17341
# Address of instruction:       0x16f9e
# Address of next instruction:  0x16fa4
# Relative difference:          0x39d (925)
#
# Given that we want to jump to 0x17327 instead, which is 26 bytes of address
# closer (0x17341 - 0x17327), you might think that we need to work with
# a relative difference of 0x383 (899) but there's a slight catch.
#
# The instruction that is there, JNE, takes two bytes to express, and the new
# instruction, JMP, is a single byte instruction.  That means that if we don't
# want to mess with the rest of the program, we have to pad with an instruction
# that does nothing, NOP, for No OPeration.
#
# Since the next instruction is now the NOP, which is now one byte closer, we
# must recalculate the offset using a relative difference of 0x384 or 900.
#
# The final two things you need to know to patch IOKit are the opcodes for the
# three instructions, and the endianness of the architecture.
#
# JNE is '0x0F 0x85', JMP is '0xE9', and NOP is '0x90'.
#
# Intel x86 is little endian, which means the small byte of a multi-byte number
# comes first (the little end comes first). This means that the four byte
# offset 0x0000039D will be in the instruction stream as 0x9D 0x03 0x00 0x00
#
# So, finally, the existing instruction is JNE +925, or JNE +0x39D, which is
# encoded as:
# (0F 85) JNE (9D 39 00 00) +925
# 0F 85 9D 39 00 00
#
# The instructions we want to replace it with are JMP +900, NOP, or JMP +0x384,
# NOP, which is encoded as:
# (E9) JMP (84 03 00 00) +900 (90) NOP
# E9 84 03 00 00 90
#
# Converting this into a perl command like below, you'll notice that the before
# and after bytes are exactly the same as in the 10.9.1 version.  We test this
# by patching the local copy of IOKit with thw following command
#
# perl -i.bak -pe '$before = qr"\x0F\x85\x9D\x03\x00\x00"s;s/$before/\xE9\x84\x03\x00\x00\x90/g'  IOKit
#
# We'll disassemble the newly patched file to make sure it does what we expect:
# otool -vt IOKit > IOKit_new.asm
#
# We compare the two versions:
# diff -u IOKit.asm IOKit_new.asm
#
# Looking at the output shows that the only difference is replacing the JNE
# with the two instructions, JMP (or JMPQ) and NOP.
#
# The final step is taking the md5 hash of the new version and updating this file:
# md5 -q /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
# 45d8fc0e1210f0672297a7716478990e


if [ "$iokit_md5_current" = "$iokit_md5_10_7_4_patched" ]; then
	echo "Detected patched IOKit on 10.7.4, no action taken."
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_7_5_patched" ]; then
	echo "Detected patched IOKit on 10.7.5, no action taken."
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_8_3_patched" ]; then
	echo "Detected patched IOKit on 10.8.3, no action taken."
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_8_4_patched" ]; then
	echo "Detected patched IOKit on 10.8.4, no action taken."
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_8_5_12F45_patched" ]; then
	echo "Detected patched IOKit on 10.8.5, no action taken."
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_9_1_patched" ]; then
	echo "Detected patched IOKit on 10.9.1, no action taken."
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_9_2_patched" ]; then
	echo "Detected patched IOKit on 10.9.2, no action taken."
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_8_3_patched" ]; then
	echo "Detected patched NVIDIA driver on 10.8.3, no action taken."
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_8_4_patched" ]; then
	echo "Detected patched NVIDIA driver on 10.8.4, no action taken."
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_8_5_12F45_patched" ]; then
	echo "Detected patched NVIDIA driver on 10.8.5, no action taken."
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_9_1_patched" ]; then
	echo "Detected patched NVIDIA driver on 10.9.1, no action taken."
fi


if [ "$amd_md5_current" = "$amd_md5_10_9_1_patched" ]; then
	echo "Detected patched AMD Driver on 10.9.1, no action taken."
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_7_4" ]; then
	echo "Detected unpatched IOKit on 10.7.4, patching."
        sudo perl -i.bak -pe '$before = qr"\xF6\xC1\x01\x74\x0A"s;s/$before/\xE9\x71\x03\x00\x00/g' /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
        sudo touch /System/Library/Extensions
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_7_5" ]; then
	echo "Detected unpatched IOKit on 10.7.5, patching."
        sudo perl -i.bak -pe '$before = qr"\xF6\xC1\x01\x74\x0A"s;s/$before/\xE9\x71\x03\x00\x00/g' /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
        sudo touch /System/Library/Extensions
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_8_3" ]; then
	echo "Detected unpatched IOKit on 10.8.3, patching."
        sudo perl -i.bak -pe '$before = qr"\x0F\x85\xDE\x03\x00\x00"s;s/$before/\xE9\xC5\x03\x00\x00\x90/g' /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
        sudo touch /System/Library/Extensions
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_8_4" ]; then
	echo "Detected unpatched IOKit on 10.8.4, patching."
        sudo perl -i.bak -pe '$before = qr"\x0F\x85\xDE\x03\x00\x00"s;s/$before/\xE9\xC5\x03\x00\x00\x90/g' /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
        sudo touch /System/Library/Extensions
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_8_5_12F45" ]; then
	echo "Detected unpatched IOKit on 10.8.5, patching."
        sudo perl -i.bak -pe '$before = qr"\x0F\x85\xDE\x03\x00\x00"s;s/$before/\xE9\xC5\x03\x00\x00\x90/g' /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
        sudo touch /System/Library/Extensions
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_9_1" ]; then
	echo "Detected unpatched IOKit on 10.9.1, patching."
        sudo perl -i.bak -pe '$before = qr"\x0F\x85\x9D\x03\x00\x00"s;s/$before/\xE9\x84\x03\x00\x00\x90/g' /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
        sudo touch /System/Library/Extensions
fi


if [ "$iokit_md5_current" = "$iokit_md5_10_9_2" ]; then
	echo "Detected unpatched IOKit on 10.9.2, patching."
        sudo perl -i.bak -pe '$before = qr"\x0F\x85\x9D\x03\x00\x00"s;s/$before/\xE9\x84\x03\x00\x00\x90/g' /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
        sudo touch /System/Library/Extensions
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_8_3" ]; then
	echo "Detected unpatched NVIDIA driver on 10.8.3, patching."
	sudo perl -i.bak -pe '$oldLimit1 = qr"\xC7\x82\xC8\x00\x00\x00\x88\x84\x02\x00"s;$newLimit1 = "\xC7\x82\xC8\x00\x00\x00\x80\x1A\x06\x00";$oldLimit2 = qr"\xC7\x82\x10\x01\x00\x00\x88\x84\x02\x00"s;$newLimit2 = "\xC7\x82\x10\x01\x00\x00\x80\x1A\x06\x00";s/$oldLimit1/$newLimit1/g;s/$oldLimit2/$newLimit2/g' /System/Library/Extensions/NVDAGK100Hal.kext/Contents/MacOS/NVDAGK100Hal
        sudo touch /System/Library/Extensions
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_8_4" ]; then
	echo "Detected unpatched NVIDIA driver on 10.8.4, patching."
	sudo perl -i.bak -pe '$oldLimit1 = qr"\xC7\x82\xD0\x00\x00\x00\x88\x84\x02\x00"s;$newLimit1 = "\xC7\x82\xD0\x00\x00\x00\x80\x1A\x06\x00";$oldLimit2 = qr"\xC7\x82\x20\x01\x00\x00\x88\x84\x02\x00"s;$newLimit2 = "\xC7\x82\x20\x01\x00\x00\x80\x1A\x06\x00";s/$oldLimit1/$newLimit1/g;s/$oldLimit2/$newLimit2/g' /System/Library/Extensions/NVDAGK100Hal.kext/Contents/MacOS/NVDAGK100Hal
	sudo touch /System/Library/Extensions
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_8_5_12F45" ]; then
	echo "Detected unpatched NVIDIA driver on 10.8.5, patching."
	sudo perl -i.bak -pe '$oldLimit1 = qr"\xC7\x82\xD0\x00\x00\x00\x88\x84\x02\x00"s;$newLimit1 = "\xC7\x82\xD0\x00\x00\x00\x80\x1A\x06\x00";$oldLimit2 = qr"\xC7\x82\x20\x01\x00\x00\x88\x84\x02\x00"s;$newLimit2 = "\xC7\x82\x20\x01\x00\x00\x80\x1A\x06\x00";s/$oldLimit1/$newLimit1/g;s/$oldLimit2/$newLimit2/g' /System/Library/Extensions/NVDAGK100Hal.kext/Contents/MacOS/NVDAGK100Hal
	sudo touch /System/Library/Extensions
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_9_1" ]; then
	echo "Detected unpatched NVIDIA driver on 10.8.4, patching."
	sudo perl -i.bak -pe '$oldLimit1 = qr"\xC7\x82\xD0\x00\x00\x00\x88\x84\x02\x00"s;$newLimit1 = "\xC7\x82\xD0\x00\x00\x00\x80\x1A\x06\x00";$oldLimit2 = qr"\xC7\x82\x20\x01\x00\x00\x88\x84\x02\x00"s;$newLimit2 = "\xC7\x82\x20\x01\x00\x00\x80\x1A\x06\x00";s/$oldLimit1/$newLimit1/g;s/$oldLimit2/$newLimit2/g' /System/Library/Extensions/NVDAGK100Hal.kext/Contents/MacOS/NVDAGK100Hal
	sudo touch /System/Library/Extensions
fi


if [ "$amd_md5_current" = "$amd_md5_10_9_1" ]; then
	echo "Detected unpatched AMD driver on 10.9.1, patching."
	sudo perl -i.bak -pe '$oldLimit1 = qr"\x75\x0C\x49\x81\x7E\x28\x40\xB3\xD5\x09"s;$newLimit1 = "\x75\x0C\x49\x81\x7E\x28\x00\x84\xD7\x17";$oldLimit2 = qr"\xFF\xFF\x48\x81\x7D\x80\x41\xB3\xD5\x09"s;$newLimit2 = "\xFF\xFF\x48\x81\x7D\x80\x01\x84\xD7\x17";s/$oldLimit1/$newLimit1/g;s/$oldLimit2/$newLimit2/g' /System/Library/Extensions/AMDSupport.kext/Contents/MacOS/AMDSupport
	sudo touch /System/Library/Extensions
fi

