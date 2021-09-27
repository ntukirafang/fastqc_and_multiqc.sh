#!/bin/bash
i=0
while true
do
	ls /mnt/libobio_MGI/analysis_output_wgs >/mnt/dell5820/PFI/multi-QC_report/newly_name_list
  #scanning the folder(Purpose: To check whether have the new folder) 
       cat /mnt/dell5820/PFI/multi-QC_report/old_name_list | sort >/mnt/dell5820/PFI/multi-QC_report/old_name_list.sort
       #sort the older list
       cat /mnt/dell5820/PFI/multi-QC_report/newly_name_list | sort >/mnt/dell5820/PFI/multi-QC_report/newly_name_list.sort
       #sort the new list
multiQC_newly_list=/mnt/dell5820/PFI/multi-QC_report/newly_name_list.sort
multiQC_older_list=/mnt/dell5820/PFI/multi-QC_report/old_name_list.sort
Date=$(date +%Y/%m/%d/%T)
for newly_file in $(join -v 2 $multiQC_older_list $multiQC_newly_list ); do
#compare the two list whether have the new file
echo "$newly_file" "$Date" 
Real_date=$(echo $Date | tr '/' '_')
sleep 1
if [ -d /mnt/libobio_MGI/analysis_output_wgs/$newly_file ]; then
#new file check
	cat /mnt/dell5820/PFI/multi-QC_report/old_name_list | sort >/mnt/dell5820/PFI/multi-QC_report/old_name_list.sort
	if [ -f /mnt/libobio_MGI/analysis_output_wgs/$newly_file/cmd.o ]; then
  #check status whether have the output message
		Finish=$(cat /mnt/libobio_MGI/analysis_output_wgs/$newly_file/cmd.o|tail -n1)
    #Finish message
		Error=$(cat /mnt/libobio_MGI/analysis_output_wgs/$newly_file/cmd.e|head -n1)
		#Error message
    echo $Finish
		echo $Error
		if [[ $Finish == "Done" ||$Error == "ERROR: Run pipeline error" ]] ; then
    #one of status to indicate the file is already analysis
			echo 'WES_analysis_is_done'
			echo $newly_file is prepared for multiQC analysis >> /mnt/dell5820/PFI/multi-QC_report/MultiQC_log"_"$Real_date
      #creat a log
			mkdir /mnt/dell5820/WES_QC/$newly_file
      #creat a output folder
			cp /mnt/libobio_MGI/analysis_output_wgs/$newly_file/sample.list /mnt/dell5820/WES_QC/$newly_file
			ChIP_ID=$( cat /mnt/dell5820/WES_QC/$newly_file/sample.list | awk '{if(NR==1) print$2}'|cut -f2|awk -F"," '{print}'| awk -F"/" '{print $NF}'|awk -F"_" '{print $1}')
			echo $ChIP_ID > /mnt/dell5820/WES_QC/$newly_file/ChIP_ID
      #check the CHIP ID
			if [[ $(cat /mnt/dell5820/WES_QC/$newly_file/ChIP_ID| cut -c 1) == "S" || $(cat /mnt/dell5820/WES_QC/$newly_file/ChIP_ID| cut -c 1) == "s" ]]; then
				echo $newly_file, "machine : MGI200" > /mnt/dell5820/WES_QC/$newly_file/machine.txt
			elif [[ $(cat /mnt/dell5820/WES_QC/$newly_file/ChIP_ID| cut -c 1) == "V" || $(cat /mnt/dell5820/WES_QC/$newly_file/ChIP_ID| cut -c 1) == "v" ]]; then
				echo $newly_file, "machine : MGI2000" > /mnt/dell5820/WES_QC/$newly_file/machine.txt
			elif [[ $(cat /mnt/dell5820/WES_QC/$newly_file/ChIP_ID| cut -c 1) == "K" || $(cat /mnt/dell5820/WES_QC/$newly_file/ChIP_ID| cut -c 1) == "k" ]]; then
				echo $newly_file, "machine : MGI200" > /mnt/dell5820/WES_QC/$newly_file/machine.txt
			elif [ $(cat /mnt/dell5820/WES_QC/$newly_file/ChIP_ID| awk -F"_" '{print $1}') == "JB20" ]; then
				echo $newly_file, "machine : MGI2000" > /mnt/dell5820/WES_QC/$newly_file/machine.txt
			else
				echo $newly_file, "machine : None" > /mnt/dell5820/WES_QC/$newly_file/machine.txt
			fi
      #check the loop of barcode
			longer_line=$( cat /mnt/dell5820/WES_QC/$newly_file/sample.list|cut -f2|wc -L)
			normal_line=$( cat /mnt/dell5820/WES_QC/$newly_file/sample.list|cut -f2|awk -F',' '{print$1}'|wc -L )
			longest_barcode=$(echo|awk 'BEGIN{print int('$longer_line/$normal_line+0.5')}')
			for ((l=1;l<=$longest_barcode;l=l+1 ));do
				line_content=$(cat /mnt/dell5820/WES_QC/$newly_file/sample.list|cut -f2|awk -F',' '{print$'$l'}'|awk -F"/" '{print $NF}'|sed 's/ /\n/g')
				echo $line_content |sort|sed 's/ /\n/g' >> /mnt/dell5820/WES_QC/$newly_file/list_fastq
			done
			folder_path=$( cat /mnt/dell5820/WES_QC/$newly_file/sample.list |awk '{if(NR==1) print$3}'|awk -F',' '{print$1}'|awk -F"/" 'OFS="/"{$NF="";print}'|sed "s/....$//g"|sed 's/volume1/mnt/g'|sed 's/volume2/mnt/g')
			echo $folder_path
			cd $folder_path
			folder_length=$(ls |grep "L0"|wc -l)
			echo $folder_length
			folder_list=$(ls |grep "L0")
			echo $folder_list
			for ((m=1; m<=$folder_length; m=m+1 )); do
				Land_folder=$(echo $folder_list|awk -F" " '{print$'$m'}')
				echo $Land_folder
				cd $folder_path/$Land_folder
				if [[ $(ls *.fq.gz|sort |awk '{if(NR==1) print}'|awk -F"_" '{print$4}' ) == "1.fq.gz" ]];then
        #pair end check
					echo "paired_sample"
					fastq1=$(ls *.fq.gz|grep "_1.fq.gz"|sort|sed 's/ /\n/g')
					echo $fastq1| sed 's/ /\n/g' >/mnt/dell5820/WES_QC/$newly_file/fastq1_list
					fastq2=$(ls *.fq.gz|grep "_2.fq.gz"|sort|sed 's/ /\n/g')
					echo $fastq2| sed 's/ /\n/g' >/mnt/dell5820/WES_QC/$newly_file/fastq2_list
					open_list_fastq1=$(cat /mnt/dell5820/WES_QC/$newly_file/list_fastq |grep "$Land_folder"|sort)
					echo $open_list_fastq1| sed 's/ /\n/g' >/mnt/dell5820/WES_QC/$newly_file/open_list_fastq1
					open_list_fastq2=$(cat /mnt/dell5820/WES_QC/$newly_file/list_fastq |grep "$Land_folder"|sort|sed 's/1.fq.gz/2.fq.gz/g')
					echo $open_list_fastq2| sed 's/ /\n/g' >/mnt/dell5820/WES_QC/$newly_file/open_list_fastq2
					fastq1_path=/mnt/dell5820/WES_QC/$newly_file/fastq1_list
					fastq2_path=/mnt/dell5820/WES_QC/$newly_file/fastq2_list 
					open_fastq1_path=/mnt/dell5820/WES_QC/$newly_file/open_list_fastq1
					open_fastq2_path=/mnt/dell5820/WES_QC/$newly_file/open_list_fastq2
					real_fastq1=$(join $fastq1_path $open_fastq1_path)
					real_fastq2=$(join $fastq2_path $open_fastq2_path)
					/home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-0.11.9/fastqc -o /mnt/dell5820/WES_QC/$newly_file/ -f fastq $real_fastq1 $real_fastq2 /home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-pfi/Configuration/limits.txt -t 10
				rm /mnt/dell5820/WES_QC/$newly_file/fastq1_list
				rm /mnt/dell5820/WES_QC/$newly_file/fastq2_list
				rm /mnt/dell5820/WES_QC/$newly_file/open_list_fastq1
				rm /mnt/dell5820/WES_QC/$newly_file/open_list_fastq2
				else 
					echo "single_sample"
          #single end
					/home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-0.11.9/fastqc -o /mnt/dell5820/WES_QC/$newly_file/ -f fastq $folder_path/$Land_folder/*.fq.gz /home/jimmy/anaconda3/pkgs/fastqc-0.11.9-0/opt/fastqc-pfi/Configuration/limits.txt -t 10
				fi
			done
			sample_length=$( cat /mnt/dell5820/WES_QC/$newly_file/sample.list | cut -f1|wc -l )
			for ((j=1; j<=$sample_length; j=j+1 )); do
				echo "$newly_file" "$Real_date" > /mnt/dell5820/PFI/multi-QC_report/log.$Real_date
				sample_ID=$(cat /mnt/dell5820/WES_QC/$newly_file/sample.list| awk '{if(NR=='$j') print$1}')
				mkdir /mnt/dell5820/WES_QC/$newly_file/$sample_ID
				mkdir /mnt/dell5820/WES_QC/$newly_file/$sample_ID/fastqc
				wget http://192.168.30.15/report/wes/$newly_file/04.GetReport/$sample_ID/$sample_ID\_cn.html -O /mnt/dell5820/WES_QC/$newly_file/$sample_ID/$sample_ID\_cn.html
				wget http://192.168.30.15/report/wes/$newly_file/04.GetReport/$sample_ID/$sample_ID\.vcfstat.xls  -O /mnt/dell5820/WES_QC/$newly_file/$sample_ID/$sample_ID\.vcfstat.xls
				Novel_SNP=$(cat /mnt/dell5820/WES_QC/$newly_file/$sample_ID/$sample_ID\.vcfstat.xls|sed '/Novel_SNP\t/!d'|cut -f2)
				Novel_SNP_Rate=$(cat /mnt/dell5820/WES_QC/$newly_file/$sample_ID/$sample_ID\.vcfstat.xls|grep 'Novel_SNP_Rate'|cut -f2)
				TiTv=$(cat /mnt/dell5820/WES_QC/$newly_file/$sample_ID/$sample_ID\.vcfstat.xls|grep 'Ti/Tv'|cut -f2)
				Total_INDEL=$(cat /mnt/dell5820/WES_QC/$newly_file/$sample_ID/$sample_ID\.vcfstat.xls|grep 'Total_INDEL'|cut -f2)
				echo sample_name Novel_SNP Novel_SNP_RATE TITV Total_INDEL >> /mnt/dell5820/WES_QC/$newly_file/$sample_ID/sample_QC.txt
				echo $sample_ID $Novel_SNP $Novel_SNP_Rate $TiTv $Total_INDEL >> /mnt/dell5820/WES_QC/$newly_file/$sample_ID/sample_QC.txt
				barcode_length=$(cat /mnt/dell5820/WES_QC/$newly_file/sample.list|awk '{if(NR=='$j') print}'|cut -f2|awk -F"," '{print NF}')
				for ((k=1; k<=$barcode_length; k=k+1 )); do	
					barcode_list1=$(cat /mnt/dell5820/WES_QC/$newly_file/sample.list|grep "$sample_ID"|cut -f2|awk -F"," '{print$'$k'}'| awk -F"/" '{print $NF}')
					barcode_list2=$(cat /mnt/dell5820/WES_QC/$newly_file/sample.list|grep "$sample_ID"|cut -f3|awk -F"," '{print$'$k'}'| awk -F"/" '{print $NF}')
					html_file1=$(echo $barcode_list1|sed 's/.fq.gz/_fastqc.html/g')
					html_file2=$(echo $barcode_list2|sed 's/.fq.gz/_fastqc.html/g')
					zip_file1=$(echo $barcode_list1|sed 's/.fq.gz/_fastqc.zip/g')
					zip_file2=$(echo $barcode_list2|sed 's/.fq.gz/_fastqc.zip/g')
					cd /mnt/dell5820/WES_QC/$newly_file/
					mv $html_file1 /mnt/dell5820/WES_QC/$newly_file/$sample_ID
					mv $html_file2 /mnt/dell5820/WES_QC/$newly_file/$sample_ID
					mv $zip_file1 /mnt/dell5820/WES_QC/$newly_file/$sample_ID
					mv $zip_file2 /mnt/dell5820/WES_QC/$newly_file/$sample_ID
				done
				/home/jimmy/anaconda3/bin/multiqc /mnt/dell5820/WES_QC/$newly_file/$sample_ID -o /mnt/dell5820/WES_QC/$newly_file/$sample_ID
				mv /mnt/dell5820/WES_QC/$newly_file/$sample_ID/*fastqc.html /mnt/dell5820/WES_QC/$newly_file/$sample_ID/fastqc
			done
			rm /mnt/dell5820/WES_QC/$newly_file/fastq1_list
			rm /mnt/dell5820/WES_QC/$newly_file/fastq2_list
			rm /mnt/dell5820/WES_QC/$newly_file/open_list_fastq1
			rm /mnt/dell5820/WES_QC/$newly_file/open_list_fastq2
			rm /mnt/dell5820/WES_QC/$newly_file/list_fastq
			echo echo $Date , "Done" > /mnt/dell5820/PFI/multi-QC_report/log.Finish
			echo  $newly_file>>/mnt/dell5820/PFI/multi-QC_report/old_name_list
			echo -e $newly_file,"\n"$Date,"\n""Done" > /mnt/dell5820/WES_QC/$newly_file/Finish.log
			if [[ $Error == "ERROR: Run pipeline error" ]]; then
				mv /mnt/dell5820/WES_QC/$newly_file /mnt/dell5820/WES_QC/$newly_file\_error
			fi
		elif [[ $(cat /mnt/libobio_MGI/analysis_output_wgs/$newly_file/cmd.e|tail -n1) == "ERROR: Run pipeline error" ]]; then
			echo  $newly_file>>/mnt/dell5820/PFI/multi-QC_report/old_name_list	
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

