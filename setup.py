from setuptools import Extension, setup
from Cython.Build import cythonize
import os


with open("README.md", 'r') as f:
    long_description = f.read()


jxlpy_ext = Extension(
    name="_jxlpy",
    sources=["_jxlpy/_jxl.pyx" if os.path.exists("_jxlpy/_jxl.pyx") else "_jxlpy/_jxl.cpp"],
    include_dirs=[],
    extra_compile_args=['-O2'],
    extra_link_args=['-ljxl', '-ljxl_threads'],
    language='c++',
)


setup(name='jxlpy',
      version='0.9.4',
      description='JPEG XL integration in Python',
      long_description=long_description,
      long_description_content_type='text/markdown',
      license='MIT License',
      author='oloke',
      author_email='olokelo@gmail.com',
      url='http://github.com/olokelo/jxlpy',
      packages=['jxlpy'],
      package_data={
          'jxlpy': ['*.pyx', '*.py'],
          '': ['README.md']
      },
      include_package_data=True,
      install_requires=['cython'],
      extras_require={'pillow': ['Pillow']},
      python_requires='>=3.4',
      ext_modules=cythonize([jxlpy_ext]),
      classifiers=[
          'Development Status :: 3 - Alpha',
          'Intended Audience :: Developers',
          'Topic :: System :: Archiving :: Compression',
          'Topic :: Multimedia :: Graphics',
          'Topic :: Multimedia :: Graphics :: Graphics Conversion',
          'Operating System :: OS Independent',
          'License :: OSI Approved :: MIT License',
          'Programming Language :: Cython',
          'Programming Language :: Python :: 3'
      ]
)
