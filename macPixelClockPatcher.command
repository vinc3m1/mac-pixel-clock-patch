#!/bin/bash
iokit_md5_current="$(md5 -q /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit)"
nvda_md5_current="$(md5 -q /System/Library/Extensions/NVDAGK100Hal.kext/Contents/MacOS/NVDAGK100Hal)"

iokit_md5_10_7_4=b1e6fb797d7d3470acabe7c06e6c139e
iokit_md5_10_7_5=0176a6d9a7c3b8c39bb06785fcdfca6d
iokit_md5_10_8_3=9bf853999cff6ee4158d3fa2acc0ce7c
iokit_md5_10_8_4=233a4256b845b647b151739c87070695
iokit_md5_10_8_5_12F45=5d69bf9227997dfad5e48fa87bd14598

iokit_md5_10_7_4_patched=92eb38917f6ec4f341bff6fd1b6076ed
iokit_md5_10_7_5_patched=b5b15d1ed5a404962bc7de895a0df56a
iokit_md5_10_8_3_patched=289039239535c91146518c64aea5907b
iokit_md5_10_8_4_patched=8c70a0ca62bf65e9ffa8667e2871c287
iokit_md5_10_8_5_12F45_patched=de3ad8279077c675ae8093193deb253f

nvda_md5_10_8_3=6a2d5017b6ddd3d19de2f4039d4c88ec
nvda_md5_10_8_4=b553fd25b25d2262317e9de758888d2b
nvda_md5_10_8_5_12F45=f84d891f1a67aa278453be59a6e1fece

nvda_md5_10_8_3_patched=7e8372fca35c5e7db90a229e70709d58
nvda_md5_10_8_4_patched=3c552ba24fa89b2ea892dd711088e8d5
nvda_md5_10_8_5_12F45_patched=5e65da83006468e8a69ef60a180ea08d


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


if [ "$nvda_md5_current" = "$nvda_md5_10_8_3_patched" ]; then
	echo "Detected patched NVIDIA driver on 10.8.3, no action taken."
fi


if [ "$nvda_md5_current" = "$nvda_md5_10_8_4_patched" ]; then
	echo "Detected patched NVIDIA driver on 10.8.4, no action taken."
fi

if [ "$nvda_md5_current" = "$nvda_md5_10_8_5_12F45_patched" ]; then
	echo "Detected patched NVIDIA driver on 10.8.5, no action taken."
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
