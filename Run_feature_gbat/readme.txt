�������Σ�
����ĳ��IP��������µ�feature֮����ҪΪ����ʹ�õ���IP��NPI��������feature�ļ��������ʹ�øýű���
-d ָ������Ŀ¼
-i ָ��ipname���ַ�����
�ű���������NotePad++�ַ������ù���
�ű�����������ָ��Ŀ¼���������а�����IP���ַ�������Ϣ����������������浽��ǰĿ¼��search_IP.txt�ļ�
֮������������ȥ����ӦNPI��feature gbat
�������н����������ڣ��������NPI��feature gbat ���ִ��� �����и�NPI feature gbat������log ��������ǰĿ¼�µ�run_feature_error_log�ļ���
ע�⣺Ϊ��߽ű������ٶȣ��ýű��ڼ���IPʱ��ֻ����ָ��Ŀ¼�µ�blocksĿ¼���.add �� .inst �ļ�

Applicable circumstances��
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