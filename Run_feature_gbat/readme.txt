适用情形：
当在某个IP中添加了新的feature之后，需要为所有使用到该IP的NPI重新生成feature文件，则可以使用该脚本。
-d 指定搜索目录
-i 指定ipname（字符串）
脚本具有类似NotePad++字符搜索得功能
脚本首先在搜索指定目录下搜索所有包含该IP（字符串）信息，并将搜索结果保存到当前目录下search_IP.txt文件
之后根据搜索结果去跑相应NPI的feature gbat
并将运行结果输出到窗口，如果允许NPI的feature gbat 出现错误 则将运行该NPI feature gbat产生的log 保存至当前目录下的run_feature_error_log文件中
注意：为提高脚本运行速度，该脚本在检索IP时，只检索指定目录下的blocks目录里的.add 和 .inst 文件

Applicable circumstances：
After you add a new feature to an IP, you need to regenerate the feature file for all NPI that use this IP. At this point, you can use the script to complete the work.

Instructions:
  1. open cmd
  2. ruby Run_feature_gbat.rb -d C:\mcu-chipmodel\chipmodel\soc -i d_ip_llwu_syn.itmp
     * Parameter "-d " : Specify the directory which we want to search in chipmodel
       such as "-d C:\mcu-chipmodel\chipmodel\soc", "C:\mcu-chipmodel\chipmodel\soc\kinetis"
     * Parameter "-i " : Specify the ipname which we want to search
       such "-i d_ip_llwu_syn.itmp", "d_ip_llwu_syn"

Features:
  Search results are stored in search_ipname.txt
  When run feature gbat, the error log are stored in run_feature_error_log folder
  
Notice:
  Scripts search IP by search the string in .add and .inst files which in blocks folder in given directory.
  So the Scripts in only suitable to search IP information. 