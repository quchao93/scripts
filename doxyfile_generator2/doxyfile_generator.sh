#!/bin/bash

# chips name
generate_chips=(LPC54114 LPC54608)



echo 'Release chips to generate doxyfile:'
for chip in ${generate_chips[@]}
do
	echo $chip
	# For the moment, we will delete the independent list output for each chip.
	# If you would like to keep these files, just remove the '-d' option below.
	python ./doxyfile_generator.py -c $chip >> /dev/null 2>&1
done
