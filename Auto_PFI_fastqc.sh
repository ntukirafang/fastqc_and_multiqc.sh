#!/bin/bash
i=0
while true
do
	ls /mnt/libobio_MGI/analysis_output_pfi >/home/report/PFI_QC_report/newly_name_list
       cat /home/report/PFI_QC_report/old_name_list | sort >/home/report/PFI_QC_report/old_name_list.sort
       cat /home/report/PFI_QC_report/newly_name_list | sort >/home/report/PFI_QC_report/newly_name_list.sort
multiQC_newly_list=/home/report/PFI_QC_report/newly_name_list.sort
multiQC_older_list=/home/report/PFI_QC_report/old_name_list.sort
Date=$(date +%Y/%m/%d/%T)
for newly_file in $(join -v 2 $multiQC_older_list $multiQC_newly_list ); do
echo "$newly_file" "$Date" 
Real_date=$(echo $Date | tr '/' '_')
sleep 1
if [ -d /mnt/libobio_MGI/analysis_output_pfi/$newly_file ]; then
	cat /home/report/PFI_QC_report/old_name_list | sort >/home/report/PFI_QC_report/old_name_list.sort
	if [ -f /mnt/libobio_MGI/analysis_output_pfi/$newly_file/shell/*.log ]; then
		Finish=$(cat /mnt/libobio_MGI/analysis_output_pfi/$newly_file/shell/*.log|tail -n1|awk -F":" '{print$4}'|sed 's/ //g' )
		echo $Finish
		if [ $Finish == "Finishalltasks" ]; then
			echo 'PFI_analysis_is_done'
			echo $newly_file is prepared for multiQC analysis >> MultiQC_log"_"$Real_date
			mkdir /mnt/dell5820/yuchi/PFI_QC/$newly_file
			cp /mnt/libobio_MGI/analysis_output_pfi/$newly_file/input.list /mnt/dell5820/yuchi/PFI_QC/$newly_file
			cp /mnt/libobio_MGI/analysis_output_pfi/$newly_file/00.Rawdata/sample.list /mnt/dell5820/yuchi/PFI_QC/$newly_file
			ChIP_ID=$( cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/input.list | awk '{if(NR==1) print$3}'| awk -F"/" '{print $NF}'|awk -F"_" '{print $1}')
			echo $ChIP_ID > /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID
			if [[ $(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID| cut -c 1) == "S" || $(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID| cut -c 1) == "s" ]]; then
				echo $newly_file, "machine : MGI200" > /mnt/dell5820/yuchi/PFI_QC/$newly_file/machine.txt
			elif [[ $(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID| cut -c 1) == "V" || $(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID| cut -c 1) == "v" ]]; then
				echo $newly_file, "machine : MGI2000" > /mnt/dell5820/yuchi/PFI_QC/$newly_file/machine.txt
			elif [[ $(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID| cut -c 1) == "K" || $(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID| cut -c 1) == "k" ]]; then
				echo $newly_file, "machine : MGI200" > /mnt/dell5820/yuchi/PFI_QC/$newly_file/machine.txt
			elif [ $(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/ChIP_ID| awk -F"_" '{print $1}') == "JB20" ]; then
				echo $newly_file, "machine : MGI2000" > /mnt/dell5820/yuchi/PFI_QC/$newly_file/machine.txt
			else
				echo $newly_file, "machine : None" > /mnt/dell5820/yuchi/PFI_QC/$newly_file/machine.txt
			fi

			fastq_path=$(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/input.list|awk '{if(NR==1) print$3}'|awk -F"/" 'OFS="/"{$NF="";print}'|sed 's/volume1/\mnt/g'| sed 's/volume2/\mnt/g')
			cd $fastq_path
			if [[ $(ls *.fq.gz|sort |awk '{if(NR==1) print}'|awk -F"_" '{print$4}' ) == "1.fq.gz" ]];then
				echo "paired_sample"
				fastq1=$(ls *.fq.gz|sort|grep "_1.fq.gz")
				fastq2=$(ls *.fq.gz|sort|grep "_2.fq.gz")
				/home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-0.11.9/fastqc -o /mnt/dell5820/yuchi/PFI_QC/$newly_file/ -f fastq $fastq1 $fastq2 --limits /home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-pfi/Configuration/limits.txt -t 10
			else 
				echo "single_sample"
				/home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-0.11.9/fastqc -o /mnt/dell5820/yuchi/PFI_QC/$newly_file/ -f fastq $fastq_path/*.fq.gz  --limits /home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-pfi/Configuration/limits.txt -t 10
			fi
			sample_length=$( cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/sample.list | cut -f1|wc -l )
			for ((j=1; j<=$sample_length; j=j+1 )); do
				echo "$newly_file" "$Real_date" > /home/report/PFI_QC_report/log.$Real_date
				sample_ID=$(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/sample.list| awk '{if(NR=='$j') print$1}')
				mkdir /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID
				mkdir /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID/fastqc
				cp /mnt/libobio_MGI/analysis_output_pfi/$newly_file/01.QC/$sample_ID.QC.txt /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID/$sample_ID.QC.txt
				cp /mnt/libobio_MGI/analysis_output_pfi/$newly_file/Result/$sample_ID/$sample_ID\_cn.html /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID/$sample_ID\_cn.html
				barcode_list=$(cat /mnt/dell5820/yuchi/PFI_QC/$newly_file/input.list|grep "$sample_ID"|cut -f3| awk -F"/" '{print $NF}')
				html_file=$(echo $barcode_list|sed 's/.fq.gz/_fastqc.html/g')
				zip_file=$(echo $barcode_list|sed 's/.fq.gz/_fastqc.zip/g')
				cd /mnt/dell5820/yuchi/PFI_QC/$newly_file/
				mv $html_file /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID
				mv $zip_file /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID
				/home/jimmy/anaconda3/bin/multiqc /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID -o /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID
				mv /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID/*fastqc.html /mnt/dell5820/yuchi/PFI_QC/$newly_file/$sample_ID/fastqc
			done
			rm *.html
			rm *.zip
			echo echo $Date , "Done" > /home/report/PFI_QC_report/log.Finish
			echo  $newly_file>> /home/report/PFI_QC_report/old_name_list
			echo -e $newly_file,"\n"$Date,"\n""Done" > /mnt/dell5820/yuchi/PFI_QC/$newly_file/Finish.log
		else
			echo "This data still process"
			break
		fi
	else
		echo "This data is not well prepared. break"
		break
	fi
else
	echo $i"NO new file in folder."
fi
echo 'sleep 2 hour'
	sleep 1
		declare -i i=i+1
done
done

