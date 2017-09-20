#!/usr/bin/python
# -*- coding: utf-8 -*-
#Filename : doxyfile_generator2.py
#This doxyfile_generator2 applies to release 7.

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
#components file name
file_components = 'components.yml'
#template file name
rm_doxyfile_template = 'Doxyfile_lib_PDF_RM'
changelog_doxyfile_template = 'Doxyfile_lib_PDF_ChangeLog'
#suffix for multicore. Need to be update, if there are more suffix.
suffix_for_multicore = ['', '_cm0plus', '_cm4', '_M0P', '_M4', '_CORE0', '_CORE1']
#middleware list. Need to be update, if there are more middlewares.
middleware_list_dic = {'aws_iot': ['middleware/aws_iot', 'middleware/aws_iot'], 'emv': ['', 'middleware/emv'], 'emwin': ['middleware/emwin', 'middleware/emwin'], 'fatfs': ['', 'middleware/fatfs'],
'lwip': ['', 'middleware/lwip'], 'mbedtls': ['', 'middleware/mbedtls'], 'mmcau': ['middleware/mmcau', 'middleware/mmcau'], 'multicore': ['', 'middleware/multicore'],
'ntag_i2c_plus': ['middleware/ntag_i2c_plus', 'middleware/ntag_i2c_plus'], 'sdmmc': ['middleware/sdmmc', 'middleware/sdmmc'], 'usb': ['', 'middleware/usb'], 'wifi_qca': ['middleware/wifi_qca', 'middleware/wifi_qca'], 'wolfssl': ['', 'middleware/wolfssl'], 'freertos': ['', 'rtos']}
 

## Read the options input by using the command line.
def __read_options():
    # Tool arg parser.
    parser = argparse.ArgumentParser(
                formatter_class=argparse.RawDescriptionHelpFormatter,
                description='Tool for doxygen list generaion.')

    # Options
    parser.add_argument('-c', '--chipname', help='The chip name. A chip name is needed for every generaion to distinguish itself from others.')
    parser.add_argument('-r', '--rootdir', default=None, help="The root directory, which is the directory of the SDK project. If you have edited the 'rootdir' in the py file, you do not need to concern about it in the command line.")
    parser.add_argument('-t', '--type', help="The function type of the Doxyfile-Generator. 'rm' for Reference Manual Doxyfile and 'changelog' for ChangeLog Doxyfile.")
    
    return parser.parse_args()

#get components.yml file by match chipname in fix directory 
def __get_components_files(chip_name, componentsdir):
    components_files_list = []
    for (dirpath, dirnames, filenames) in os.walk(componentsdir):
        for name in dirnames:
            for suffix in suffix_for_multicore:
                target_name = chip_name + suffix
                if (target_name == name):
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
    middleware_dir_list = []
    ##Get all components
    for component_file_dir in components_files_list:
        component_file = open(component_file_dir, 'r')
        for line in component_file.readlines():
            components_in_file.append(line)
        component_file.close()
    ##Filter duplicate component    
    all_components = set(components_in_file)
    for component in all_components:
        if re.match(r'^- bin/generator/records/msdk/components/(drivers|cmsis_drivers|utilities)/.*yml$', component) != None:
            searchobj = re.sub('^- ', '', component, 1)
            searchobj = searchobj.strip('\n')
            components_dir_list.append(rootdir + '/' + searchobj)
        elif re.search(r'^- bin/generator/records/msdk/components/middlewares/(.*?)(/.*yml$)', component) != None:
            target_middleware = re.search(r'^- bin/generator/records/msdk/components/middlewares/(.*?)(/.*yml)', component).group(1)
            # print target_middleware
            if function_type == 'rm':
                # if middleware_list_dic.has_key(target_middleware):
                    # if middleware_list_dic[target_middleware][0] != '':
                        # middleware_dir_list.append(middleware_list_dic[target_middleware][0])
                # else:
                    # print '\nWarning:  Not find middleware:' + target_middleware + '. Please update middleware_list_dic in script.'
                pass
            elif function_type == 'changelog':
                if middleware_list_dic.has_key(target_middleware):
                    if middleware_list_dic[target_middleware][1] != '':
                        middleware_dir_list.append(middleware_list_dic[target_middleware][1])
                else:
                    print '\nWarning:  Not find middleware:' + target_middleware + '. Please update middleware_list_dic in script.'
    # print middleware_dir_list
    return (components_dir_list, middleware_dir_list)

#process driver.yml to get the driver path
def __process_components_list(chip_name, components_list, middleware_list):
    components_dir = []
    for component in components_list:
        # (filepath,tempfilename) = os.path.split(component)
        # (filename,extension) = os.path.splitext(tempfilename)
        # component_name = filename.replace('drv_', 'driver.')
        # print component
        component_name = ''
        path = ''
        file = open(component, 'r')
        for line in file.readlines():
            if re.match('^(driver|utility|utilities).*:', line) != None:
                component_name = line.strip(':\n')
                break
        file.close
        file = open(component, 'r')
        yml = yaml.load(file)
        # print component_name
        # print yml
        try:
            number = len(yml[component_name]['contents']['cc-include'])
            if number > 1:
                for i in range(number):
                    multi_path = yml[component_name]['contents']['cc-include'][i]['path']
                    components_dir.append(multi_path)
            path = yml[component_name]['contents']['cc-include'][0]['path']
            # print path
        except KeyError:
            try:
                filename = yml[component_name]['contents']['files'][0]['source']
                path = os.path.split(filename)[0];
                # print path
            except KeyError:
                print "\nWarning: Not find path for :" + component_name
        if 'devices/${platform_devices_soc_name}' in path:
            path = 'devices/${platform_devices_soc_name}/drivers'
            path = path.replace('${platform_devices_soc_name}', chip_name)
        # print path
        components_dir.append(path)
        file.close

    #Add middleware dictory 
    components_dir = components_dir + middleware_list
    #Remove duplicate elements
    components_dir_list = list(set(components_dir))
    components_dir_list.sort()
    return components_dir_list
    
#Add additional information, including clock.dox power.dox 
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
    
    return components_dir_list
    
def __format_input(all_inputdata):
    input_data = []
    image_path = []
    for num, data in enumerate(all_inputdata):
        if (num == 0):
            pre_fixdir = 'INPUT                  = '
        else:
            pre_fixdir = space
        input_data.append(pre_fixdir + fixdir + data)
    for num, data in enumerate(all_inputdata):
        if (num == 0):
            pre_fixdir = 'IMAGE_PATH             = '
        else:
            pre_fixdir = space
        image_path.append(pre_fixdir + fixdir + data)
    return (input_data, image_path)
    
def __format_feature(feature_dic):
    feature_data = []
    for num, data in enumerate(feature_dic):
        pre_fixdir = space
        feature = pre_fixdir + fixdir + data + '=' + feature_dic[data]
        feature_data.append(feature)
    return feature_data

#generate doxyfile for specific soc
def __generate_doxyfile(chip_name, input_data, image_path, feature_data):
    
    if function_type == 'rm':
        file_doxyfile_template = 'Doxyfile_lib_PDF_RM'
    elif function_type == 'changelog':
        file_doxyfile_template = 'Doxyfile_lib_PDF_ChangeLog'
    else:
        print "Please enter a valid function type!\ne.g. '-t rm' or '-t changelog'.\n"
        sys.exit()

    # Firstly, open the template file to read all lines in.
    f_file_doxyfile = open(file_doxyfile_template, 'r')
    lines = f_file_doxyfile.readlines()
    f_file_doxyfile.close()
    target_doxyfile = file_doxyfile_template + '_' + chip_name
    # Define two flags for targeting the INPUT lines
    flag_find_input = False
    flag_find_end_input = False
    # Define two flags for targeting the PREDEFINED lines
    flag_find_predefined = False
    flag_find_end_predefined = False
    # Define two flags for targeting the PREDEFINED lines
    flag_find_image_path = False
    flag_find_end_image_path = False
    
    # Any time the fixed INPUT changed from Doxyfile Template, this also needs an update.
    fixdir_input = '                         ./ \\\n                         ../common/trademarks/trademarks_template.md \\\n                         mainpage.md \\\n                         architectural_overview.md\n'
    fixdir_image = '                         ../common/trademarks/FS_COLOR_LOGOSM_JPG.jpg \\\n                         ../common/trademarks/arm_logo.png \\\n                         ../common/trademarks/EES-FSL.png \\\n                         ../../mk/doxygen \\\n                         ./ \\\n                         Kinetis_SDK_Block_Diagram.png \\\n                         kpsdk_guide01.png \\\n                         ../../../platform/drivers/src/tsi/doxygen'
    
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
        # IMAGE_PATH
        if not flag_find_image_path:
            if re.search(r'IMAGE_PATH             = ', line, re.I) != None:
                for data in image_path:
                    f_file_doxyfile.write(data + ' \\\n')
                f_file_doxyfile.write(fixdir_image)
                flag_find_image_path = True
                continue
        if flag_find_image_path:
            if not flag_find_end_image_path:
                if not line.strip() == "":
                    f_file_doxyfile.write("")
                    continue
                else:
                    flag_find_end_image_path = True
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
        print 'You need to give a chip name for this Doxyfile generaion.\nThe name can distinguish itself from a next time generaion, such as python doxyfile_generator2.py -c MK63F12'
        sys.exit()
    else:
        chip_name = the_args.chipname
    if the_args.type == None:
        print 'You need to give a function type for this Doxyfile generaion.\n\"rm\" for Reference Manual Doxyfile and \"changelog\" for ChangeLog Doxyfile,such as python doxyfile_generator.py -c MK10D10 -t rm.'
        sys.exit()
    else:
        function_type = the_args.type.lower()
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
    components_list, middleware_list = __get_components_list(components_files_list)
    #Process driver yml, like: adc.yml
    components_dir_list = __process_components_list(chip_name, components_list, middleware_list)
    #Add other useful information, like:clock.dox, power.dox, utilities and middleware
    all_inputdata = __add_input_information(chip_name, components_dir_list, feature_dic)
    #Format the input information
    input_data, image_path = __format_input(all_inputdata)
    #Format the feature information
    feature_data = __format_feature(feature_dic)
    
    #Generate doxyfile
    doxyfile = __generate_doxyfile(chip_name, input_data, image_path, feature_data)
    
    print '\nGenerate doxyfile sucessed!'
    