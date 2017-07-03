#!/usr/bin/python
#Usage:
# python autobuild_tool.py [iar|keil|armgcc|kds|atl] debug 
# python autobuild_tool.py [iar|keil|armgcc|kds|atl] release
# python autobuild_tool.py [iar|keil|armgcc|kds|atl]

import re,os,sys,subprocess,shutil

rootDir = r"C:\Users\B58848\Desktop\Package\78\SDK_2.0_FRDM-K32W042"

enableParallelBuilding = False # True or False

warningList = []
errorList = []

fileNameExtention = {'iar':'.ewp','keil':'.uvprojx','armgcc':'CMakeLists.txt','kds':'.cproject','atl':'.cproject'}
environmentVariable = {'iar':'IAR_WORKBENCH','keil':'KEIL','kds':'KDS_WORKBENCH','atl':'ATL_WORKBENCH'}

sectionLine = "*" * 79
startInfo = "    Build start "
endInfo = "    Build finish "
script_dir, script_name = os.path.split(os.path.abspath(sys.argv[0])) 

def searchToolChainBinPath(toolchain):
    try:
        workbenchPath = os.environ[environmentVariable[toolchain]]
    except KeyError:
        raise RuntimeError(environmentVariable[toolchain]+" environment variable is not set.")
    else:
        if toolchain == 'iar':
            return os.path.normpath(os.path.join(workbenchPath, "common", "bin", "IarBuild.exe"))
        elif toolchain == 'keil':
            return os.path.normpath(os.path.join(workbenchPath, "UV4.exe"))
        else:
            return workbenchPath
    
# Get the project name by parsing the .project file
def getProjectName(path):
    with open(path) as fd:
        for line in fd:
            m = re.match(r'<name>(\S+)</name>', line.strip())
            if m:
                projectName = m.group(1)
                break
    return projectName  
    
def iarProjectBuilder(iar_path, project_file, target_version):
    target_version = target_version.capitalize()
    project_path = os.path.dirname(project_file)
    print (sectionLine + "\n" + startInfo + project_path + " --" + target_version + "\n")    

    p = subprocess.Popen([iar_path, project_file, '-make', target_version, '-log', 'info', '-parallel', '4'],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=0)
    
    build_log, err = p.communicate()
    
    #print build_log
    if p.returncode != 0:
        # Build failed
        errorList.append((project_path, target_version, build_log))
        print "**  Build failed."
    else:
        if build_log.find('License check failed') >= 0:
            print 'License check failed!'
            return
        # Check warning
        m = re.search(r'Total number of warnings: (\d+)', build_log)
        if m and int(m.group(1)) > 0: 
           warningList.append((project_path, target_version, build_log))
        else:
           print "    Build succeed!"

    print ('\n' + endInfo + project_path + " --" + target_version + "\n")

def keilProjectBuilder(keil_path, project_file, target_version):
    
    project_path = os.path.dirname(project_file)
    target_version = target_version.capitalize()
    projectName = os.path.basename(project_file).split('.')[0]   
    
    print (sectionLine + "\n" + startInfo + project_path + " --" + target_version + "\n")

    p = subprocess.Popen([keil_path, '-b', project_file, '-j0', '-o', target_version
            + '_log.txt', '-t', projectName + ' ' + target_version],
            stdout=None, stderr=subprocess.STDOUT, bufsize=0)
    returncode = p.wait()
    
    if returncode != 0:
        with open(os.path.dirname(project_file) + os.sep + target_version + '_log.txt', "r") as f:
            contents = f.readlines()
            #convert to string
            build_log = ''.join(contents)
    if returncode == 1: # Warning
        warningList.append((project_path, target_version, build_log))
        print "**  Success with warnings."
    elif returncode == 0:
        print "    Build succeed!"
    else:
        errorList.append((project_path, target_version, build_log))
        print "**  Build failed."

    print ('\n' + endInfo + project_path + " --" + target_version + "\n")


def armgccProjectBuilder(dummy, project_file, target_version):

    project_path = os.path.dirname(project_file)
    os.chdir(project_path)
    print (sectionLine + "\n" + startInfo + project_path + " --" + target_version + "\n")

    build_name = 'build_'+ target_version.lower() + '.bat'
    p = subprocess.Popen('call ' + build_name + '< nul', stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=0, shell=True)
    
    build_log, err = p.communicate()
    
    #print build_log    
    if p.returncode != 0:
        # Build failed
        errorList.append((project_path, target_version, build_log))
        print 'Build failed!'
    else:
        # Check warning
        if build_log.find('warning:') >= 0:
           warningList.append((project_path, target_version, build_log))
        else:
           print "    Build succeed!"

    print ('\n' + endInfo + project_path + " --" + target_version + "\n")
    
def kdsProjectBuilder(kds_path, project_file, target_version):
    project_path = os.path.dirname(project_file)
    if enableParallelBuilding == True:
        # enable parallel building
        with open(project_file,'r+') as f:
            content = f.readlines()
            f.seek(0)        
            for index,line in enumerate(content):
                if 'parallelBuildOn="false"' in line:
                    content[index] = line.replace('parallelBuildOn="false"', 'parallelBuildOn="true" parallelizationNumber="optimal"')
            f.writelines(content)
            
    import_path = os.path.dirname(project_file)    

    print (sectionLine + "\n" + startInfo + project_path + " --" + target_version + "\n")

    if os.path.isdir('./kds_workspace/.metadata'):
        shutil.rmtree('./kds_workspace/.metadata')
    kds_build_cmd = 'set path=%s;%s;%s && "%s" --launcher.suppressErrors -nosplash -application "org.eclipse.cdt.managedbuilder.core.headlessbuild" -build "%s" -import "%s" -data "%s" ' % (
                kds_path + '/ide',
                kds_path + '/ARMTools/bin',
                '%SystemRoot%\system32;%SystemRoot%',
                kds_path + '/eclipse/kinetis-design-studio',
                getProjectName(import_path+'\.project') + '/' + target_version,
                import_path,
                './kds_workspace',
                )
    #print kds_build_cmd

    p = subprocess.Popen(kds_build_cmd, bufsize=0, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    build_log, err = p.communicate()
    #print build_log
    if p.returncode != 0:
        # Build failed
        errorList.append((project_path, target_version, build_log))
        print "**  Build failed."
    else:
        # Check warning
        if build_log.find('warning:') >= 0:
           warningList.append((project_path, target_version, build_log))
        else:
           print "    Build succeed!"

    print ('\n' + endInfo + project_path + " --" + target_version + "\n")

def atlProjectBuilder(atl_path, project_file, target_version):

    project_path = os.path.dirname(project_file)
    if enableParallelBuilding == True:
        # enable parallel building
        with open(project_file,'r+') as f:
            content = f.readlines()
            f.seek(0)        
            for index,line in enumerate(content):
                if '<builder ' in line:
                    pos = line.find('<builder ')                    
                    content[index] = line[:pos+9] + 'parallelBuildOn="true" parallelizationNumber="optimal" ' + line[pos+9:]
            f.writelines(content)
    
    import_path = os.path.dirname(project_file)

    print (sectionLine + "\n" + startInfo + project_path + " --" + target_version + "\n")

    if os.path.isdir('./atl_workspace/.metadata'):
        shutil.rmtree('./atl_workspace/.metadata')

    atl_build_cmd = 'set path=%s;%s;%s && "%s" --launcher.suppressErrors -nosplash -application "org.eclipse.cdt.managedbuilder.core.headlessbuild" -build "%s" -import "%s" -data "%s" ' % (
                atl_path + '/ide',
                atl_path + '/ARMTools/bin',
                '%SystemRoot%\system32;%SystemRoot%',
                atl_path + '/ide/TrueSTUDIO',
                getProjectName(import_path+'\.project') + '/' + target_version,
                import_path,
                './atl_workspace',
                )
    #print atl_build_cmd
    p = subprocess.Popen(atl_build_cmd, bufsize=0, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    build_log, err = p.communicate()

    #print build_log
    if p.returncode != 0:
        # Build failed
        errorList.append((project_path, target_version, build_log))
        print "**  Build failed."
    else:
        # Check warning
        if build_log.find('warning:') >= 0:
           warningList.append((project_path, target_version, build_log))
        else:
           print "    Build succeed!"

    print ('\n' + endInfo + project_path + " --" + target_version + "\n")

#Generate project list
def generateProjectList(toolchain, rootdir):
    project_list = []
    for parent,dirnames,filenames in os.walk(rootdir):
        for filename in filenames:
            project_file = os.path.join(parent,filename)
            if not 'boards' in project_file:
                continue
            if toolchain == 'atl' and not 'atl' in project_file:
                continue
            if toolchain == 'kds' and not 'kds' in project_file:
                continue    
            if project_file.endswith(fileNameExtention[toolchain]):
                project_list.append(project_file)               
                #print project_file
    return project_list
    
def main():

    targetVersion = ''
    projectBuilder= {'iar':iarProjectBuilder,'keil':keilProjectBuilder,'armgcc':armgccProjectBuilder,
    'kds':kdsProjectBuilder,'atl':atlProjectBuilder} 
    
    argvLength = len(sys.argv)
    if argvLength == 1:
        print "Usage:"
        print "python autobuild_tool.py [iar|keil|armgcc|kds|atl] [debug|relase]"
        print "python autobuild_tool.py [iar|keil|armgcc|kds|atl]"
        print "Toolchain must be specified, default build version is all"
        exit(0) 
    elif argvLength == 2:
        toolChain = sys.argv[1].lower()
    else:
        toolChain = sys.argv[1].lower()
        targetVersion = sys.argv[2].lower()            
    
    projectList = generateProjectList(toolChain, rootDir)
    
    if toolChain == 'armgcc':
        toolChainBinPath = ''
    else:
        toolChainBinPath = searchToolChainBinPath(toolChain)
    try:   
        for item in projectList:
            #print item        
            if not targetVersion == '':
                    projectBuilder[toolChain](toolChainBinPath, item, targetVersion)
            else:
                if toolChain == 'kds' or toolChain == 'atl':
                    projectBuilder[toolChain](toolChainBinPath, item, 'debug|release')
                else:
                    projectBuilder[toolChain](toolChainBinPath, item, 'debug')
                    projectBuilder[toolChain](toolChainBinPath, item, 'release')
    except KeyboardInterrupt:
        dumpLog(toolChain)
        sys.exit()
        

    print sectionLine
    print "          %s   BUILD   FINISH" %toolChain.upper()
    print sectionLine    

    # Print projects with warnings.
    if warningList:
        print "Projects with warnings:"
        print
        for proj in warningList:
            print proj[0] + " --" + proj[1]
            print 59*'-'
    else:
        print "** No warnings detected."

    # print project with errors
    if errorList > 0:
        print len(errorList), " builds failed:"
        print 
        for failed_project in errorList:
            print failed_project[0] + " --" + failed_project[1]
            print 59*'-'    

        print sectionLine
    else:
        print "** all builds succeeded."
        print sectionLine
    dumpLog(toolChain)
    
def dumpLog(toolchain):   
    with open(script_dir + os.sep + toolchain + '_build_log.txt','w') as f:
        print >>f, sectionLine
        print >>f, "          %s   BUILD   FINISH" %toolchain.upper()
        print >>f, sectionLine
        # project with errors
        if errorList > 0:
            print >>f, len(errorList), " builds failed:\n"
            #print 
            for failed_project in errorList:
                print >>f, failed_project[0] + " --" + failed_project[1]
                print >>f, failed_project[2]
                print >>f, 59*'-'    

            print >>f, sectionLine
        else:
            print >>f, "** all builds succeeded."
            print >>f, sectionLine
        # projects with warnings.
        if warningList:
            print >>f, "Projects with warnings:\n"
            for proj in warningList:
                print >>f, proj[0] + " --" + proj[1]
                print >>f, proj[2]
                print >>f, 59*'-'
        else:
            print >>f, "** No warnings detected."
    print "Check the %s_build_log.txt for warning and error which loacated in %s" %(toolchain,script_dir)

if __name__ == "__main__":
    main()