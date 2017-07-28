#!/usr/bin/python
# -*- coding: utf-8 -*-
#Filename : doxyfile_generator2.py

import re, sys, argparse, os, yaml, msvcrt
from feature_parser import FeatureParser

# Replace the root directory with your own repo position.
# This is the default root directory if you lance the script from doxyfile_generator folder.
rootdir = r'../../..'
# The fixed directory of Doxyfile INPUT. Need to update once changed.
fixdir = '../../../'
# The fixed empty space of Doxyfile INPUT lines. Need to update once changed.
space = '                         '
# The directory of components yml files
dir_components = '/bin/generator/records/msdk/components/socs'
# The directory of msdk
dir_msdk = '/bin/generator/records/'
#components file name
file_components = 'components.yml'
#template file name
file_doxyfile_template = 'Doxyfile_lib_PDF_RM'

## Read the options input by using the command line.
def __read_options():
    # Tool arg parser.
    parser = argparse.ArgumentParser(
                formatter_class=argparse.RawDescriptionHelpFormatter,
                description='Tool for doxygen list generaion.')

    # Options
    parser.add_argument('-c', '--chipname', help='The chip name. A chip name is needed for every generaion to distinguish itself from others.')
    parser.add_argument('-r', '--rootdir', default=None, help="The root directory, which is the directory of the SDK project. If you have edited the 'rootdir' in the py file, you do not need to concern about it in the command line.")
    # parser.add_argument('-t', '--type', help="The function type of the Doxyfile-Generator. 'rm' for Reference Manual Doxyfile and 'changelog' for ChangeLog Doxyfile.")
    
    return parser.parse_args()

#get components.yml file by match chipname in fix directory 
def __get_components_files(chip_name, componentsdir):
    components_files_list = []
    for (dirpath, dirnames, filenames) in os.walk(componentsdir):
        for name in dirnames:
            if (chip_name in name):
                # targetfile = os.path.join(dirpath, name) + '/' + file_components
                targetfile = dirpath + '/' + name + '/' + file_components
                if os.path.isfile(targetfile):
                    components_files_list.append(targetfile)
    if  len(components_files_list) > 1:
        print "There are multiple components.yml files!"
        for components_file in components_files_list:
            print components_file
    elif len(components_files_list) == 1:
        print "There is one components.yml file!"
        for components_file in components_files_list:
            print components_file
    elif len(components_files_list) == 0:
        print "No components.yml was not found! Please enter a valid chip name."
        sys.exit()
    return components_files_list

#process components.yml to get all driver.yml
def __get_components_list(components_files_list):
    
    components_in_file = []
    components_dir_list = []
    ##Get all components
    for dir_file_components in components_files_list:
        components_file = open(dir_file_components, 'r')
        for line in components_file.readlines():
            components_in_file.append(line)
        components_file.close()
    ##Filter duplicate    component    
    all_components = set(components_in_file)
    for component in all_components:
        if re.match(r'^- msdk/.*drivers.*yml$', component) != None:
            searchobj = re.sub('^- ', '', component, 1)
            # searchobj = re.sub('/', r'\\', searchobj)
            searchobj = searchobj.strip('\n')
            components_dir_list.append(rootdir + dir_msdk + searchobj)
    # print len(components_dir_list)
    # for components_dir in components_dir_list:
        # print components_dir
    return components_dir_list

#process driver.yml to get the driver path
def __process_components_list(chip_name, components_list):
    components_dir = []
    driver_name = ''
    path = ''
    for component in components_list:
        # (filepath,tempfilename) = os.path.split(component)
        # (filename,extension) = os.path.splitext(tempfilename)
        # driver_name = filename.replace('drv_', 'driver.')
        file = open(component, 'r')
        for line in file.readlines():
            if re.match('^driver.*:', line) != None:
                driver_name = line.strip(':\n')
                break
        file.close
        file = open(component, 'r')
        yml = yaml.load(file)
        # print "**************************************************"
        # print driver_name
        path = yml[driver_name]['contents']['cc-include'][0]['path']
        if '${platform_devices_soc_name}' in path:
            path = yml[driver_name]['contents']['files'][0]['source']
            path = path.replace('${platform_devices_soc_name}', chip_name)
        # print path
        components_dir.append(path)
        #Remove duplicate elements
        components_dir_list = list(set(components_dir))
        components_dir_list.sort()
        file.close
    return components_dir_list
    
#Add additional information, including clock.dox power.dox middleware utilities.
def __add_input_information(chip_name, components_dir_list, feature_dic):
    #default add clock.dox path
    components_dir_list.append('platform/drivers/clock')
    if feature_dic.has_key('FSL_FEATURE_SOC_SCG_COUNT'):
        components_dir_list.append('platform/drivers/scg')
    elif feature_dic.has_key('FSL_FEATURE_SOC_MCG_COUNT'):
        components_dir_list.append('platform/drivers/mcg')
    elif feature_dic.has_key('FSL_FEATURE_SOC_MCGLITE_COUNT'):
        components_dir_list.append('platform/drivers/mcglite')
    
    #Add power.dox path, for LPC series.
    power_driver = 'platform/' + chip_name + '/fsl_power.h'
    if power_driver in components_dir_list:
        components_dir_list.append('platform/drivers/power')
    
    #Add utilities
    components_dir_list.append('platform/utilities/debug_console')
    components_dir_list.append('platform/utilities/notifier')
    components_dir_list.append('platform/utilities/shell')
    
    #Add middleware
    if feature_dic.has_key('FSL_FEATURE_SOC_DMAMUX_COUNT') or feature_dic.has_key('FSL_FEATURE_SOC_DMA_COUNT') or feature_dic.has_key('FSL_FEATURE_SOC_EDMA_COUNT'):
        components_dir_list.append('platform/middleware/dma_manager')
    if feature_dic.has_key('FSL_FEATURE_SOC_MMCAU_COUNT'):
        components_dir_list.append('platform/middleware/mmcau')
    if feature_dic.has_key('FSL_FEATURE_SOC_SDHC_COUNT') or feature_dic.has_key('FSL_FEATURE_SOC_DSPI_COUNT') or feature_dic.has_key('FSL_FEATURE_SOC_SPI_COUNT'):
        components_dir_list.append('platform/middleware/sdmmc')
    # for component in components_dir_list:
        # print component
    return components_dir_list
    
def __formate_input(all_inputdata):
    input_data = []
    for num, data in enumerate(all_inputdata):
        if (num == 0):
            pre_fixdir = 'INPUT                  = '
        else:
            pre_fixdir = space
        input_data.append(pre_fixdir + fixdir + data)
    # for data in input_data:
        # print data
    return input_data
    
def __formate_feature(feature_dic):
    feature_data = []
    for num, data in enumerate(feature_dic):
        # if (num == 0):
            # pre_fixdir = 'PREDEFINED             = '
        # else:
            # pre_fixdir = space
        pre_fixdir = space
        feature = pre_fixdir + fixdir + data + '=' + feature_dic[data]
        feature_data.append(feature)
    # for feature in feature_data:
        # print feature
    return feature_data

#generate doxyfile for specific soc
def __generate_doxyfile(chip_name, file_doxyfile_template, input_data, feature_data):
    target_doxyfile = file_doxyfile_template + '_' + chip_name
    
    # Firstly, open the template file to read all lines in.
    f_file_doxyfile = open(file_doxyfile_template, 'r')
    lines = f_file_doxyfile.readlines()
    f_file_doxyfile.close()
    
    # Secondly, open the output file and write data in.
    # Define two flags for targeting the INPUT lines
    flag_find_input = False
    flag_find_end_input = False
    # Define two flags for targeting the PREDEFINED lines
    flag_find_predefined = False
    flag_find_end_predefined = False
    
    # Any time the fixed INPUT changed from Doxyfile Template, this also needs an update.
    fixdir_input = '                         ./ \\\n                         ../common/trademarks/trademarks_template.md \\\n                         mainpage.md \\\n                         architectural_overview.md\n'
    
    f_file_doxyfile = open(target_doxyfile, 'w')
    for i, line in enumerate(lines):
        # INPUT
        if not flag_find_input:
    	    if re.search(r'INPUT                  = ', line, re.I) != None:
                for data in input_data:
                    f_file_doxyfile.write(data + ' \\\n')
                f_file_doxyfile.write(fixdir_input)
                flag_find_input = True
                continue
        if flag_find_input:
            if not flag_find_end_input:
                if not line.strip() == "":
                    f_file_doxyfile.write("")
                    continue
                else:
                    flag_find_end_input = True
                    f_file_doxyfile.write(line)
                    continue
        # PREDEFINED
        if not flag_find_predefined:
            if re.search(r'PREDEFINED             = ', line, re.I) != None:
                f_file_doxyfile.write(line)
                # For the last line of PREDEFINED, no need to add '\\\n'; for the others, need this
                for count in range (0, (len(feature_data) - 1)):
                    line = feature_data[count]
                    f_file_doxyfile.write(line + ' \\\n')
                # Write the last line of feature_list
                f_file_doxyfile.write(feature_data[len(feature_data) - 1] + '\n')
                flag_find_predefined = True
                continue
        if flag_find_predefined:
            if not flag_find_end_predefined:
                if not line.strip() == "":
                    f_file_doxyfile.write("")
                    continue
                else:
                    flag_find_end_predefined = True
                    f_file_doxyfile.write(line)
                    continue

        if ((not flag_find_input) and (not flag_find_predefined)) or (flag_find_input and flag_find_predefined) or ((not flag_find_predefined) and flag_find_end_input) or ((not flag_find_input) and flag_find_end_predefined):
            f_file_doxyfile.write(line)

    f_file_doxyfile.close()
    
## The main function process.
if __name__ == '__main__':
    
    # Get the command line args
    the_args = __read_options()
    
    # Reads the tool options
    if the_args.chipname == None:
        print 'You need to give a chip name for this Doxyfile generaion.\nThe name can distinguish itself from a next time generaion, such as python doxyfile_generator2.py -c MK10D10'
        sys.exit()
    else:
        chip_name = the_args.chipname
    if the_args.rootdir == None:
        rootdir = rootdir
    else:
        rootdir = the_args.rootdir
    
    #Get components.yml file, like: mcu-sdk-2.0\bin\generator\records\msdk\components\socs\MK64F12\components.yml
    componentsdir = rootdir + dir_components
    components_files_list = __get_components_files(chip_name, componentsdir)
    #Get feature.h file, like: mcu-sdk-2.0\devices\MK64F12\MK64F12_features.h
    featureParser =  FeatureParser()
    featurefile_list = featureParser.get_featurefilelist(rootdir, chip_name)
    
    #check whether the components.yml and feature.h are correct.
    print "\nPlease check whether the found files are correct?\nPress 'Enter' to continue or press any other key to quit..."
    if ord(msvcrt.getch()) != 13:
        sys.exit()
    
    #Process feature.h 
    feature_dic = featureParser.get_feature_dic(featurefile_list)
    #Process components.yml
    components_list = __get_components_list(components_files_list)
    #Process driver yml, like: adc.yml
    components_dir_list = __process_components_list(chip_name, components_list)
    #Add other useful information, like:clock.dox, power.dox, utilities and middleware
    all_inputdata = __add_input_information(chip_name, components_dir_list, feature_dic)
    #Formate the input information
    input_data = __formate_input(all_inputdata)
    #Formate the feature information
    feature_data = __formate_feature(feature_dic)
    
    #Generate doxyfile
    doxyfile = __generate_doxyfile(chip_name, file_doxyfile_template, input_data, feature_data)
    
    print '\nGenerate doxyfile sucessed!'
    