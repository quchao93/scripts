#!/usr/bin/python
#Filename : feature_parser.py

import os, sys, re, argparse, yaml

class FeatureParser:
    """docstring for FeatureParser"""
    
    
    def get_featurefilelist(self, rootdir, chip_name):
        featurefile_list = []
        if not os.path.isdir(rootdir + '/devices/' + chip_name):
            print "No %s was not found in %s/devices! Please enter a valid chip name." % (chip_name, rootdir)
            sys.exit()
        files = os.listdir(rootdir + '/devices/' + chip_name)
        for file in files:
            if '_features.h' in file:
                featurefile_list.append(rootdir + '/devices/' + chip_name + '/' + file)
        # print "******************************************************"
        if  len(featurefile_list) > 1:
            print "\nThere are multiple feature file!"
            for featurefile in featurefile_list:
                print featurefile
        elif len(featurefile_list) == 1:
            print "\nThere is one feature file!"
            for featurefile in featurefile_list:
                print featurefile
        elif len(featurefile_list) == 0:
             print "\nNo feature file was not found! Please enter a valid chip name."
             sys.exit()
        return featurefile_list
    
    
    def get_feature_dic(self, featurefile_list):
        issue = 0
        feature_dic = {}
        file_output = open('feature_not_be_process.txt', 'w')
        for featurefile in featurefile_list:
            file_output.write('\n\nThe file is: ' + featurefile + '\n\n')
            f_feature = open(featurefile, 'r')
            for (num, line) in enumerate(f_feature):
                if re.search(r'(#define)\s*(FSL_FEATURE_.*)\s*(\(\d*\))',line) != None:
                    target = re.search(r'(#define)\s*(FSL_FEATURE_.*)\s*(\(\d*\))',line)
                    if int(target.group(3).split('(')[1].split(')')[0]) != 0:
                        feature_dic[target.group(2).strip()] = target.group(3).split('(')[1].split(')')[0]
                    else:
                        pass
                elif re.search(r'(#define)\s*(FSL_FEATURE_.*)\s*(\(0x.+\))',line) != None:
                    target = re.search(r'(#define)\s*(FSL_FEATURE_.*)\s*(\(0x.+\))',line)
                    feature_dic[target.group(2).strip()] = target.group(3).split('(')[1].split(')')[0]
                elif re.search(r'(#define)\s*(FSL_FEATURE_.*)\s*(\(.*\))',line) != None:
                    file_output.write('Line: ' + str(num) + '   ' + line)
                    issue = issue + 1
                    # unprocess_lines.append('Line: ' + str(num) + '   ' + line.strip('\n'))
            f_feature.close
        # print '**************************************************'
        # for (feature, value) in feature_dic.items():
            # print feature + '=' + value + '\\'
            # file_output.write(feature + '=' + value + '\\\n')
        if issue != 0:
            # print '**************************************************'
            print "\nWaring: Some features' value are not processed, please see them in feature_not_be_process.txt."
            print 'You can process them maunually and add them into doxyfile.'
        return feature_dic
        

if __name__ == '__main__':
    featureParser =  FeatureParser()
    featurefile_list = featureParser.get_featurefilelist(r'../../..', 'K32W042S1M2')
    featureParser.get_feature_dic(featurefile_list)
