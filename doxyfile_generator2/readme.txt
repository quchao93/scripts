========================================================================
                            Doxyfile-Generator2

I. Introduction
===============
The Doxyfile-Generator2 is used to generate Doxyfile_lib_PDF_RM_xxxx file for one specific soc.


II. How to use
==============
Doxyfile-Generator has two modes of usage:
  - Normal mode: auto-generating Doxyfile for one specific SoC.
  - Batch mode: auto-generating Doxyfiles for a group of SoCs, for instance, SoCs of a release or any other customized SoC set.

Normal mode:
usage: doxyfile_generator.py [-h] [-c CHIPNAME] [-r ROOTDIR]

optional arguments:
  -h, --help            show this help message and exit
  -c CHIPNAME, --chipname CHIPNAME
                        The chip name. A chip name is needed for every
                        generaion to distinguish itself from others.
  -r ROOTDIR, --rootdir ROOTDIR
                        The root directory, which is the directory of the SDK
                        project. If you have edited the 'rootdir' in the py
                        file, you do not need to concern about it in the
                        command line.

e.g.:
  - RM Doxyfile generation:
    python doxyfile_generator.py -c MK64F12
  - With a specific root directory for the KSDK:
    python doxyfile_generator.py -c MK64F12 -r 'C:\workspace\mcu-sdk-2.0'
Notes:
  - The default root directory is set as the identical KSDK directory where the tool is launched. Consequently, we do not need to input a specific root dir if we lauch it for the same SDK directory.
  
Batch mode:
usage: Modify the SoC set and function type defined in the bash file (doxyfile_generator.sh) directly and then launch it. For further details, please kindly refer to the comments in the scripts.

III. How it works
=================
The Doxyfile-Generator tool summarizes the information of data in the yaml files from generator, feature header files and the specific Doxyfile requirements of Changlog/RM, to auto-prepare the Doxyfiles for input SoCs.

For the summary of feature header files, Doxyfile-Generator uses customized mapping yml files for driver and middleware mapping respectively, and a feature_parser script which parses and analyzes the yml file. The generator itself also takes the SoC generator yml files and the different requrirements for the Changelog(Release Note)/Reference Manual respectively into consideration.

For the new IPs supports and current IPs maintenance, just add/modify the IP name together with its existing conditions in map_features2drivers.yml and map_features2middlewares.yml by following the yaml rule will be enough. For more details, please consult the comments in the yml mapping files.

IV. Change log
==============
  - 5/26/2016: Initial version.
  - 7/25/2016: - Add in the mapping file and the feauture parser a new feature of override, 
                 which can override the INPUT for doxyfile of one specific module. 
                 (e.g. for the different TSI driver versions cases)
               - Fix wrong rtos INPUT typo.
  - 8/5/2017: -Modify to adopt to new generator and use new way to get drivers and features information
Note:
Please contact Zejiang Yu (zejiang.yu@nxp.com) for help when you need any detailed information or you have any question, difficulty or advice regarding the tool.
Thanks in advance.
