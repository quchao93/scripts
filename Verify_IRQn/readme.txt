

   These two ruby scripts use to check and calculate the number of occurrences for interrupt vectors in header file

   1. Verify_IRQn_one.rb 
   
   Run this scripts need specify  the parent folder of header file

   Such as "ruby Verify_IRQn_one.rb -d C:\mcu-chipmodel\npi-data\Kinetis\K3S_1M_2.4G\ksdk\K32W022S1M2_M0P"


   2. Verify_IRQn_all

   Run this scripts need specify the  Upper level directory for the parent folder of header file
   
   Such as "ruby Verify_IRQn_all.rb -d C:\mcu-chipmodel\npi-data\Kinetis\K3S_1M_2.4G\ksdk"

   This scripts can check and calculate all header files in the path


   In addition, we can use -n to specify the number of interrupt vector occurrences.

   
   All information is output in the current folder



   