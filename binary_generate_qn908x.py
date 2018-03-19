import os
import sys
import re
import shutil
import json
import xml.etree.ElementTree
from lxml import etree
import subprocess
import distutils.dir_util


class Bin_generator():
    """This class is used to generate bin files under boards/<board>/usb_examples and boards/<board>/demo_apps"""

    # This table should be confirmed with USB guys.
    usb_project_map = [
        "device_cdc_vcom_lite/bm",
        "device_composite_cdc_msc_lite/bm",
        "device_composite_hid_mouse_hid_keyboard_lite/bm",
        "device_hid_generic_lite/bm",
        "device_hid_mouse_lite/bm",
        "device_msc_ramdisk_lite/bm",
        "device_phdc_weighscale_lite/bm",
        "device_printer_virtual_plain_text_lite/bm",
        "device_video_virtual_camera_lite/bm", 
    ]
    panda_path = "bin/panda"
    
    def __init__(self, sdk_repo_path):
        self.sdk_repo_path = sdk_repo_path
        
    def enable_iar_bin_output(self, ewp_file):
        ewp_tree = xml.etree.ElementTree.parse(ewp_file)
        ewp_root = ewp_tree.getroot()
     
        output_format_node = ewp_root.findall("configuration/settings/data/option")   
        for node in output_format_node:
            if node.find('name').text == "OOCOutputFormat":
                node.find('state').text = '3'
                node.find('version').text = '3'
            if node.find('name').text == "OOCObjCopyEnable":
                node.find('state').text = '1'
        ewp_tree.write(ewp_file)
        
    def enable_armgcc_bin_output(self, cmake_list_file):
        bin_name = None
        elf_pattern = re.compile(r'\((\w+)\.elf\s')
        
        for line in open(cmake_list_file):
            m = elf_pattern.search(line)
            if m:
                bin_name = m.group(1)
                break
        
        objcmd = ('ADD_CUSTOM_COMMAND(TARGET %(bin_name)s.elf POST_BUILD COMMAND ${CMAKE_OBJCOPY} '
                  '-Obinary ${EXECUTABLE_OUTPUT_PATH}/%(bin_name)s.elf '
                  '${EXECUTABLE_OUTPUT_PATH}/%(bin_name)s.bin)') %{'bin_name':bin_name} 
            
        with open(cmake_list_file, 'a') as f:
            f.write(objcmd)


    def generate_bin_file(self, board_names, release_package_path, toolchain):
        
        missed_bin = []

        try:
            if not os.path.exists(os.path.join(release_package_path, Bin_generator.panda_path)):
                shutil.copytree(os.path.join(self.sdk_repo_path, Bin_generator.panda_path), os.path.join(release_package_path, Bin_generator.panda_path))

            pkg_dir = os.getcwd()
            
            # create project list
            os.chdir(os.path.join(release_package_path,Bin_generator.panda_path))
            temp_dir = os.getcwd()

            bin_project_list = []
            temp_root = os.path.join(release_package_path,'boards', board_name)
                                
            print "The bin file build will be implemented in " + temp_root
            sys.stdout.flush()

            # Build for USB.
            for root, dirs, files in os.walk(os.path.join(temp_root, 'usb_examples')):
                for name in files:
                    for usb_project in Bin_generator.usb_project_map:
                        full_path = os.path.join(root, name)
                        if toolchain == 'iar' and full_path.find("iar")!=-1:
                            if os.path.basename(name).split('.')[1] == 'ewp':
                                if full_path.replace('\\', '/').find(usb_project) != -1:
                                    bin_project_list.append(full_path)
                                    self.enable_iar_bin_output(full_path)
                        if toolchain == 'armgcc' and name == 'CMakeLists.txt':
                           if full_path.replace('\\', '/').find(usb_project) != -1:
                               if os.name == 'nt':
                                   bin_project_list.append(os.path.join(root, 'build_release.bat'))
                               else:
                                   bin_project_list.append(os.path.join(root, 'build_release.sh'))
                               self.enable_armgcc_bin_output(full_path)

            # Build for SDK demo.
            for root, dirs, files in os.walk(os.path.join(temp_root, 'demo_apps')):
                for name in files:
                    full_path = os.path.join(root, name)
                    if toolchain == 'iar' and full_path.find("iar")!=-1 and full_path.find("qspi") == -1:
                        if os.path.basename(name).split('.')[1] == 'ewp':
                            bin_project_list.append(full_path)
                            self.enable_iar_bin_output(full_path)
                    if toolchain == 'armgcc' and name == 'CMakeLists.txt':
                        if full_path.find("demo_app") != -1 and full_path.find("qspi") == -1:
                            if os.name == 'nt':
                                bin_project_list.append(os.path.join(root, 'build_release.bat'))
                            else:
                                bin_project_list.append(os.path.join(root, 'build_release.sh'))
                            self.enable_armgcc_bin_output(full_path)
            
            with open(os.path.join(temp_dir, "bin_project_list.txt"), 'w') as f:
                for project in bin_project_list:
                    str = "%s, Release, %s" % (project, board_name)
                    f.write("%s\n" %str)
            
            # call panda script to build projects
            if toolchain == 'iar':
                os.system("python iar_build_projects.py -f bin_project_list.txt")
            if toolchain == 'armgcc':
                os.system("python armgcc_build_projects.py -f bin_project_list.txt")

            print " Generate Bin file End"

            
            
            os.chdir(pkg_dir)
            with open(os.path.join(temp_dir, "bin_project_list.txt"), 'r') as f:
                for project in f:
                    find_bin = 0
                    project_path = os.path.join(temp_dir, os.path.dirname(project.split(',')[0]))
                    #project_path = project_path.replace('\\','/')
                    dest = os.path.dirname(project_path.replace(release_package_path,self.sdk_repo_path))                

                    for root, _, files in os.walk(project_path):
                        for file in files:
                            if len(os.path.basename(file).split('.')) > 1 and os.path.basename(file).split('.')[1] == 'bin':
                                find_bin = 1
                                # Copy the bin file from release package to git repo.
                                shutil.copy(os.path.join(root, file), dest)
                    if 0 == find_bin : 
                        missed_bin.append(project_path)
        
        except Exception, e:
            print 78*"x"
            print "Exception : " + e
        
        finally:
            if 0 == len(missed_bin):
                pass
            else:
                for mem in missed_bin:
                    print "There is no bin file in " + mem
            # Remove the log files.
            #shutil.rmtree(os.path.join(release_package_path,"bin"))


if __name__ == '__main__':

    obj_generate_bin_file = Bin_generator("C:/repo/mcu-sdk-2.0")
    toolchain = "iar"
    
    # qn908xcdk
    release_package_path = "C:/Users/B58848/Desktop/SDK_2.0.0_QN908XC"
    board_name = "qn908xcdk"
    print "%s Start ..." % board_name
    obj_generate_bin_file.generate_bin_file(board_name, release_package_path, toolchain)
    print "%s finished." % board_name
    print "Generate finished"

