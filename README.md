# JXLPy

This module introduces reading and writing support for JPEG XL directly from Python 3.

JXLPy is based on JPEG XL implementation in [imagecodecs](https://github.com/cgohlke/imagecodecs) but doesn't it require Numpy and any external dependencies besides Cython and [libjxl](https://github.com/libjxl/libjxl).

It also provides support for Pillow via plugin.

**This project is still in alpha stages and needs testing. It may contain bugs!**

## Install via PIP

```shell
$ pip install jxlpy
```

## Build it yourself

* Make sure you are using Python 3.x and pip for that version

* Build and install libjxl according to instructions [here](https://github.com/libjxl/libjxl#building)

* Install patchelf and auditwheel

  ```shell
  $ sudo apt-get install patchelf
  $ pip install auditwheel
  ```

* For Pillow plugin, make sure that Pillow is installed *(optional)*

  ```shell
  $ pip install ---upgrade pillow
  ```

* Clone this repository

  ```shell
  $ git clone https://github.com/olokelo/jxlpy
  $ cd jxlpy
  ```

* Build wheels

  ```shell
  $ pip wheel .
  ```

* Use auditwheel to put necessary libraries into your wheel

  ```shell
  $ export LD_LIBRARY_PATH=/usr/local/lib
  $ python -m auditwheel repair --plat linux_x86_64 jxlpy-*.whl
  ```
* Install newly created wheel

  ```shell
  $ cd wheelhouse
  $ pip install jxlpy-*.whl
  ```

* Now you should be good to go :)

  You can run examples to check if everything works correctly

*Installation steps were tested on Ubuntu 20.04*

## Support status

|                        Feature                        |    Status     | Importance |                 Notes                 |
| :---------------------------------------------------: | :-----------: | :--------: | :-----------------------------------: |
| Reading and writing non-animated 8 bit RGB/RGBA image |     Done      |     -      |                   -                   |
|               Creating lossless images                |     Done      |     -      |                   -                   |
|                  Reading animations                   |     Done      |     -      |                   -                   |
|                     Pillow plugin                     |    Partial    |    High    |          Animation seeking?           |
|                  Creating animations                  |    Failed     |   Medium   |                   -                   |
|                  Reading HDR images                   |     Done      |   Medium   |                   -                   |
|                  Writing HDR images                   |     Done      |    Low     |                   -                   |
|       Reading and writing floating point images       |  Not started  |    Low     |                   -                   |
|                 Support EXIF metadata                 |    Failed     |    High    |                   -                   |
|             Support for other colorspaces             |  Not started  |    Low     |                   -                   |
|        Support for lossless JPEG recompression        |  Not started  |   Medium   |                   -                   |
|      Support for progressive and responsive mode      |    Failed     |   Medium   |                   -                   |
|                 Installing on Windows                 |    Partial    |    Low     |                   -                   |

