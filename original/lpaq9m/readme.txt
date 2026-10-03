lpaq9m is a file compressor for English texts.
Must be used with DRT preprocessor.

Installation:
=============

lpaq9m d lpqdict0.enc lpqdict0.dic

To compress:
============

  drt  input  temporary_output
  lpaq9m  N  temporary_output  output

where N is 0 to 9.
Memory usage is 6 + 3*2^N MB  (9 to 1542 MB).
Larger numbers usually give better compression at similar speed.
When executing drt.exe, lpqdict0.dic must be in the current folder.

To decompress:
==============

  lpaq9m  d  input  temporary_output
  drt  temporary_output  output  d

Decompression requires the same memory as compression.

Copyright (C) 2007-2009 Alexander Ratushnyak, Matt Mahoney.
=========

    LICENSE

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details at
    Visit <http://www.gnu.org/copyleft/gpl.html>.

	See http://cs.fit.edu/~mmahoney/compression/ for the latest version.

Contents:
=========

   readme.txt	 - This file
   lpaq9m.exe	 - Windows executable
   lpaq9m.cpp	 - Source code
   DRT.exe	 - Dictionary Replace Transformer, Windows executable
   DRT		 - Linux 64-bit executable
   lpqdict0.enc  - English dictionary used by DRT.exe after decompression (to
		   lpqdict0.dic, see section Installation)

The Windows executable was compiled as follows with MinGW 3.4.2 g++
 g++ -Wall lpaq9m.cpp -O2 -Os -march=pentiumpro -fomit-frame-pointer -s -o lpaq9m.exe
and then compressed with Upack 0.399.

History:
========

July 24, 2007 - lpaq1 written by Matt Mahoney.

Sept.20, 2007 - lpaq2 improved by Alexander Ratushnyak.

Sept.29, 2007 - lpaq3a and lpaq3e improved by Alexander Ratushnyak.

Oct. 1, 2007 - lpaq4 and lpaq4e improved by Alexander Ratushnyak.

Oct.14, 2007 - lpaq5 and lpaq5e improved by Alexander Ratushnyak.
		Now you can see how to use different types of state tables
		for different models.
		This is the 1st time for LPAQ and PAQ algorithms to use a set of
		state tables.

Oct.21, 2007 - lpaq6 and lpaq6e improved by Alexander Ratushnyak.
		A simple realization of E8/E9 transform was added. May have bugs

Oct.31, 2007 - lpaq7 and lpaq7e improved by Alexander Ratushnyak.

Dec.10, 2007 - lpaq8 and lpaq8e improved by Alexander Ratushnyak.

Feb.20, 2008 - lpaq9e released by Alexander Ratushnyak.

Apr.27, 2008 - lpaq9f released by Alexander Ratushnyak.

May.22, 2008 - lpaq9g released by Alexander Ratushnyak.

June 3, 2008 - lpaq9h released by Alexander Ratushnyak.

June 12, 2008 - lpaq9i released by Alexander Ratushnyak.

Aug. 17, 2008 - lpaq9j released by Alexander Ratushnyak.

Sept.30, 2008 - lpaq9k released by Alexander Ratushnyak.
		Now you can see how to use different types of state tables
		for different contexts.
		Besides, now LPAQ can run on a 64-bit machine.
		In case you wish to use it on other platform and/or data,
		save your time, contact the developer directly: pqr#rogers.com

Nov. 30, 2008 - lpaq9l released by Alexander Ratushnyak.

Feb. 20, 2009 - lpaq9m released by Alexander Ratushnyak.
