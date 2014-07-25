Mac Pixel Clock Patcher
=====

This will remove the 165 pixel clock limiter on your display driver to support 4k @ 30Hz over HDMI.
An [Active DisplayPort to HDMI adapter](http://www.amazon.com/gp/product/B00DOZHLAA/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B00DOZHLAA&linkCode=as2&tag=makeramencom-20&linkId=TR5RNZEM24Z7KP7N) is often needed for this to work.

Based on the [original](https://code.google.com/p/mac-pixel-clock-patch/wiki/Documentation)
And the [mavericks update](https://code.google.com/r/douglas-mac-pixel-clock-patch/)


How to install this patch
=====

Download the `.command` file

Download it into your Downloads folder. Open Terminal and run:

```
cd ~/Downloads

chmod +x macPixelClockPatcher.command

./macPixelClockPatcher.command

```

You will be asked to enter your password to approve changes in your system.

Pay attention to the output - it should say it detected unpatched IOKit and NVIDIA driver on (your OS X version) and patch it.

Reboot your system.

After reboot, you should be able to get custom resolutions with over 165 MHz pixel clock to work using SwitchResX (not required after 10.9).


Instructions for updating the command for newer versions of IOKit
=====

Instructions for how to reproduce the IOKit patch on a newer version of the
binary:

First, take the md5 hash of IOKit for storing in this file
`md5 -q /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit`

For OS X 10.9.2, the result is
`9804392bbe8ba4b589175be56889c6c7`

copy IOKit local and disassemble it
```
cp /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit .
otool -vt IOKit > IOKit.asm
```

Open up that file and look for the function _CheckTimingWithRange.  You can
tell because the line begins with the function name and ends in a colon:
`_CheckTimingWithRange:`

Find the very first jump instruction in the function. In this case it is
labelled JNE, which means jump if not equal.  The instruction before is
a comparison, and a literal translation to C would be expressed as:
`if(value1 != value2) goto result;`

Now we look at the address it's jumping to.  In this case it's `0x17341`

Go down to that instruction, and you’ll see that there’s a gap between the
last jump instruction before it and this block.  That block is the cleanup
section that returns a good response.  This function is structured such that
error cases and success share the same return block, with a success block
just before the return block.

We want to patch this function so that it always returns a good response,
which means changing the first instruction to jump to the good block, which is
the first instruction to follow the very last jump to `0x17341`.  The address
of this block is `0x17327`

Jump instructions in this code are relative, se we need to calculate the
offset being used by the current instruction, and also the address that will
be used by the replacement instruction.

Relative jump instructions are stored as an offset to the following
instruction. So, in the case of the following code block:
Address
      1  JMP to 3
      2  Do Nothing
      3  Do Something

The jump instruction would be encoded as 'Jump +1', since 2 is the address of
the next instruction.  This is because the processor automatically adds the
distance to the next instruction with each instruction run, so it will be
included into the starting calculation.

For the existing code, we have the following information:
```
Instruction:                  JNE 0x17341
Address of instruction:       0x16f9e
Address of next instruction:  0x16fa4
Relative difference:          0x39d (925)
```

Given that we want to jump to 0x17327 instead, which is 26 bytes of address
closer (0x17341 - 0x17327), you might think that we need to work with
a relative difference of 0x383 (899) but there's a slight catch.

The instruction that is there, JNE, takes two bytes to express, and the new
instruction, JMP, is a single byte instruction.  That means that if we don't
want to mess with the rest of the program, we have to pad with an instruction
that does nothing, NOP, for No OPeration.

Since the next instruction is now the `NOP`, which is now one byte closer, we
must recalculate the offset using a relative difference of 0x384 or 900.

The final two things you need to know to patch IOKit are the opcodes for the
three instructions, and the endianness of the architecture.

`JNE` is `0x0F 0x85`, `JMP` is `0xE9`, and `NOP` is `0x90`.

Intel x86 is little endian, which means the small byte of a multi-byte number
comes first (the little end comes first). This means that the four byte
offset 0x0000039D will be in the instruction stream as 0x9D 0x03 0x00 0x00

So, finally, the existing instruction is `JNE +925`, or `JNE +0x39D`, which is
encoded as:
```
(0F 85) JNE (9D 39 00 00) +925
0F 85 9D 39 00 00
```

The instructions we want to replace it with are `JMP +900`, `NOP`, or `JMP +0x384`,
`NOP`, which is encoded as:
```
(E9) JMP (84 03 00 00) +900 (90) NOP
E9 84 03 00 00 90
```

Converting this into a perl command like below, you'll notice that the before
and after bytes are exactly the same as in the 10.9.1 version.  We test this
by patching the local copy of IOKit with thw following command

`perl -i.bak -pe '$before = qr"\x0F\x85\x9D\x03\x00\x00"s;s/$before/\xE9\x84\x03\x00\x00\x90/g'  IOKit`

We'll disassemble the newly patched file to make sure it does what we expect:
`otool -vt IOKit > IOKit_new.asm`

We compare the two versions:
`diff -u IOKit.asm IOKit_new.asm`

Looking at the output shows that the only difference is replacing the JNE
with the two instructions, JMP (or JMPQ) and NOP.

The final step is taking the md5 hash of the new version and updating the command file:
```
md5 -q /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
45d8fc0e1210f0672297a7716478990e
```
