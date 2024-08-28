#!/usr/bin/python
# -*- coding: utf-8 -*-
""" Script for Parsing """
# ********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
# ********************************************************************
#
#
# (c) Ericsson Radio Systems AB 2021 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Radio Systems AB, Sweden. The programs may be used
# and/or copied only with the written permission from Ericsson Radio
# Systems AB or in accordance with the terms and conditions stipulated
# in the agreement/contract under which the program(s) have been
# supplied.
#
# ********************************************************************
# Name      : parser.py
# Date      : 08/09/2021
# Revision  : main\04
# Purpose   : The script will parsing data between demarcation
# ********************************************************************
import signal
import time
import os
import sys
import subprocess
import tarfile
from datetime import date
import logging
import re
import shutil
from decimal import Decimal
import datetime
from shutil import copy2
import csv

class Parsing_Level_1:

    ''' Parsing Level 1 class '''

    def update_demark_file(self,a):
        ''' Update metadata file with the next demarcation '''
        print time.strftime("%d-%m-%Y_%H:%M:%S")+" : Update demarcation_metadata_file with next instance"
        with open("demarcation_metadata_file",'w') as demark:
            demark.seek(0)
            demark.write(a+'\n')
            demark.truncate()


        
    def get_start_end(self,file_containing_start_pattern=sys.argv[4]):
        ''' Get the file containing demarcation and the demarcation instance '''
        metadata_file = "demarcation_metadata_file"
        metadata_value = subprocess.check_output('cat %s'%(metadata_file),shell=True).strip()
        found=False
        for f_name in os.listdir('data_files/'):
            if f_name.strip().startswith('iqtrace'):
                f_name='data_files/'+f_name
                demarcation_value_in_file=os.popen('grep -wf demarcation_metadata_file %s' %(f_name.strip())).read()
                if demarcation_value_in_file:
                    found = True
                    file_found=f_name.strip()
                    demarcation_found=metadata_value
                    break
                else:
                    continue
        if not found:
            output='archived_files/'
            dir = os.listdir(output) 
            if len(dir) != 0: 
                demarcation_value_in_file=os.popen(''' zgrep -waf demarcation_metadata_file archived_files/* | awk -F: '{print $1}' | sort -u | awk -F / '{print $2}' ''').read()
                
                if demarcation_value_in_file:
                    if demarcation_value_in_file.startswith('iqtrace'):
                        found = True
                        fname=demarcation_value_in_file
                        file_found='archived_files/'+demarcation_value_in_file
                        demarcation_found=metadata_value
                        date_tz_file=fname.split('_')[-2]
                        time_tz_file=fname.split('_')[-1].split('.')[0]
                        today_date=date.today()
                        # flag check so that untarring is done only once
                        if self.flag == 0:
                            if os.path.exists(temp_folder+'/untar/'):
                                shutil.rmtree(temp_folder+'/untar/')
                            start = datetime.datetime.strptime(date_tz_file, "%d-%m-%Y")
                            end =datetime.datetime.strptime( today_date.strftime("%d-%m-%Y"),"%d-%m-%Y")
                            dates_range = (start + datetime.timedelta(days=x) for x in range(0, (end-start).days+1))
                            for date_object in dates_range:
                                for file in os.listdir(output):
                                    if file.strip().startswith('iqtrace'):
                                        if date_object.strftime("%d-%m-%Y")  == file.split('_')[-2]:
                                            if file.split('_')[-2] == date_tz_file and file.split('_')[-1].split('.')[0] < time_tz_file or file.split('_')[-2] < date_tz_file:
                                                logging.info("Filtering out the archived files whose Timestamp is not within the expected range.Hence skipping File: "+str(file))
                                                continue
                                            else:
                                                logging.info("Archive File Found whose Date/Time is within the expected range.Hence untarring the archived File: "+str(file))
                                                #print('extract'+file)
                                                out=temp_folder+'/untar'
                                                tar = tarfile.open(output+file.strip('\n'))
                                                tar.extractall(path=out)       
                                                self.flag=1
                                                #os.system('ls -larth /eniq/backup/counter_parse_tmp/untar')
            else:
                logging.info("No Files present in archived directory.")

        if not found:
            if os.path.isfile('demarcation_metadata_file_copy'):
                logging.info("Copying back previous instance as no required demarcation found in log.")
                os.system('cp demarcation_metadata_file_copy demarcation_metadata_file')
            metadata_file = "demarcation_metadata_file"
            metadata_value = subprocess.check_output('cat %s'%(metadata_file),shell=True).strip()
            if metadata_value.endswith('_demarcation_1'):
                if not os.path.exists(flag_file):
                    with open(file_containing_start_pattern.strip()) as infile, open(outputfile, 'a') as outfile:
                        copy = True
                        for line in infile:
                            if self.start_found in line:
                                print('Found start '+ str(file_containing_start_pattern.strip()))
                                copy = False
                                outfile.write(line)
                                open(flag_file, 'a').close() # touch file. as execute only 1st time
                                new=outputfile[:-1]+'0'
                                os.rename(outputfile,new)
                                logging.info("Successfully parsed data from Start of the file to the Start Demarcation. Parsed output file in "+new)
                                # save parse 1 output file in temp location
                                parsing_level_1_output = open(temp_work_dir+"/parse_1_output", "w")
                                parsing_level_1_output.write(new)
                                parsing_level_1_output.close()
                                # Cleanup
                                if os.path.exists(temp_folder):
                                    shutil.rmtree(temp_folder)
                                sys.exit()
                            else:
                                outfile.write(line)
                else:
                    logging.info("No End Demarcation present.Does not require parsing from start of the file for this subsequent first instance. ")

                    # Cleanup
                    if os.path.exists(temp_folder):
                        shutil.rmtree(temp_folder)
                    sys.exit()

            print "\33[31m{}\033[0m".format("Demarcation not found")
            logging.error("Demarcation not found")

            # Cleanup
            if os.path.exists(temp_folder):
                shutil.rmtree(temp_folder)

            exit(1)

        return demarcation_found,file_found




    def parse_level_1(self):
        """
            Parsing between demarcation post collecting information of start and end demarcation
        """
        print time.strftime("%d-%m-%Y_%H:%M:%S")+" : Get start demarcation from raw data files"
        self.flag=0
        self.start_found,file_containing_start_pattern=self.get_start_end()
        if not self.start_found or not file_containing_start_pattern:
            print "\33[31m{}\033[0m".format("No demarcation present in the logs ")
            logging.error("No demarcation present in the collected current and archive logs.")
            # Cleanup
            if os.path.exists(temp_folder):
                shutil.rmtree(temp_folder)
            exit(1)
          
        if file_containing_start_pattern:
            if file_containing_start_pattern.strip().endswith("tar.gz"): # check if file had format .tar.gz
                logging.info("Start demarcation is present in archived file:"+file_containing_start_pattern.strip())
                tar_start_file=file_containing_start_pattern
                s=file_containing_start_pattern
                os.chdir(sys.argv[1])
                logging.info("Untarring the file..... ")
                os.system('rm -rf /eniq/backup/counter_parse_tmp/untar_file_s;mkdir -p /eniq/backup/counter_parse_tmp/untar_file_s;')
                out=temp_folder+'/untar_file_s/'
                tar = tarfile.open(s.strip('\n'))
                tar.extractall(path=out)
                cmd='''ls -larth /eniq/backup/counter_parse_tmp/untar_file_s| grep log| awk '{print $NF}' '''
                file_containing_start_pattern=os.popen(cmd).read()
                file_containing_start_pattern=out+file_containing_start_pattern
                logging.info("Post Untarring, start demarcation present in :"+file_containing_start_pattern)

        logging.info("Start demarcation found :"+self.start_found)
        logging.info("Start demarcation present in :"+file_containing_start_pattern)
        instance_end=int(self.start_found.split('_')[-1])
        instance_end+=1
        a="_".join(self.start_found.split('_')[:-1])  +'_'+ str(instance_end)
        instance_end="".join(a.split())

        os.system('rm -rf demarcation_metadata_file_copy;cp demarcation_metadata_file demarcation_metadata_file_copy;')
        self.update_demark_file(instance_end)
        logging.info("Updated the demarcation file with next instance: "+instance_end)
     
        print time.strftime("%d-%m-%Y_%H:%M:%S")+" : Get end demarcation from raw data files\n"
        end_read,file_containing_end_pattern=self.get_start_end()
        if file_containing_end_pattern:
            if file_containing_end_pattern.strip().endswith("tar.gz"):
                logging.info("End demarcation is present in archived file:"+file_containing_end_pattern.strip())
                s=file_containing_end_pattern
                os.system('rm -rf /eniq/backup/counter_parse_tmp/untar_file_e;mkdir -p /eniq/backup/counter_parse_tmp/untar_file_e;')
                out=temp_folder+'/untar_file_e/'
                tar = tarfile.open(s.strip('\n'))
                tar.extractall(path=out)
                cmd='''ls -larth /eniq/backup/counter_parse_tmp/untar_file_e| grep log| awk '{print $NF}' '''
                file_containing_end_pattern=os.popen(cmd).read()
                file_containing_end_pattern=out+file_containing_end_pattern
                logging.info("Post Untarring, end demarcation present in :"+file_containing_end_pattern)
        logging.info("End demarcation found :"+end_read)
        logging.info("End demarcation present in :"+file_containing_end_pattern)

        if file_containing_start_pattern.strip() != file_containing_end_pattern.strip():
            logging.info("Start and End demarcation is not present in the same file.")
            logging.info("File with Start demarcation:"+file_containing_start_pattern.strip())
            logging.info("File with End demarcation:"+file_containing_end_pattern.strip())
            files=[file_containing_start_pattern.strip(),file_containing_end_pattern.strip()]
            if 'data_files' not in file_containing_start_pattern.strip() or 'data_files' not in file_containing_end_pattern.strip():
                _start_=file_containing_start_pattern.split('/')[-1]
                _end_=file_containing_end_pattern.split('/')[-1]

                untar_temp_dir='/eniq/backup/counter_parse_tmp/untar'
                dir = os.listdir(untar_temp_dir) 
                if len(dir) == 0: 
                    logging.info("No untarred files present in temporary tar directory")
                    if os.path.exists(temp_folder):
                        shutil.rmtree(temp_folder)
                    sys.exit()
                else:
                    logging.info("Tarred files present in temporary tar directory:"+str(dir))

                #get the file list in numbered format
                subprocess.check_output('''rm -rf /eniq/backup/counter_parse_tmp/file_list;a=0;for i in `ls -larth /eniq/backup/counter_parse_tmp/untar  | grep -E "root|dcuser" |  awk '{print $NF}'`;do a=`expr $a + 1`; echo $a,$i >> /eniq/backup/counter_parse_tmp/file_list; done;sed -i '/\,\./d' /eniq/backup/counter_parse_tmp/file_list''', shell=True)
                with open('/eniq/backup/counter_parse_tmp/file_list') as f:
                    for fn in f:
                        #if start and end file both in archived OR only start file in archived
                        if 'data_files' not in file_containing_start_pattern.strip() and 'data_files' not in file_containing_end_pattern.strip():

                            if  _start_ in fn:
                                start_file=fn.split(',')[0]
                            elif _end_ in fn:
                                end_file=fn.split(',')[0]
                        elif 'data_files' not in file_containing_start_pattern.strip():
                            if  _start_ in fn:
                                start_file=fn.split(',')[0]
                                with open('/eniq/backup/counter_parse_tmp/file_list') as f:
                                    last_line=f.readlines()[-1]
                                    end_file=int(last_line.strip().split(',')[0])
                                    end_file+=1
                        else:
                            print 'Demarcation not found in archive file'

                #get the between files
                _command_=''' rm -rf /eniq/backup/counter_parse_tmp/between_files;cat /eniq/backup/counter_parse_tmp/file_list | awk -v a=%s -v b=%s '{if((NR> a )&&(NR< b  )) print}' | awk -F, '{print$2}' > /eniq/backup/counter_parse_tmp/between_files''' % (start_file,end_file)
                subprocess.check_output(_command_, shell=True)
                file_present_in_between = os.path.isfile('/eniq/backup/counter_parse_tmp/between_files')
                if file_present_in_between:
                    total_files=[]
                    with open('/eniq/backup/counter_parse_tmp/between_files') as f:
                        for line in f:
                            total_files.append(temp_folder+'/untar/'+line.strip('\n'))
                    final_files=files[:1] + total_files + files[-1:]
                    if 'data_files' not in file_containing_start_pattern.strip() and 'data_files' not in file_containing_end_pattern.strip():
                        final_files=files[:1] + total_files + files[-1:]
                    else:
                        for fname in os.listdir('data_files/'):
                            if fname.endswith('.old'):
                                final_files.insert(-1,'data_files/'+fname)
            else:
                final_files=files
            logging.info("Total files considered from Start Demarcation to End Demarcation:"+str(final_files))
            copy = False
            for file in final_files:
                logging.info("Parsing file :"+file)
                with open(file.strip()) as infile, open(outputfile, 'a') as outfile:
                    for line in infile:
                        if "'"+self.start_found+"'" in line:
                            logging.info('Found start in '+file)
                            copy = True
                            outfile.write(line)
                            continue
                        elif end_read in line:
                            copy = False
                            logging.info('Found End in '+file)
                            outfile.write(line)
                            logging.info("Successfully parsed data from Start Demarcation to End Demarcation. Parsed output file in "+outputfile+"\n")
                            break
                        elif copy:
                            outfile.write(line)

        else:
            with open(file_containing_start_pattern.strip()) as infile, open(outputfile, 'a') as outfile:
                logging.info("Parsing file :"+str(file_containing_start_pattern.strip()))
                copy = False
                for line in infile:
                    if "'"+self.start_found+"'" in line:
                        logging.info('Found start in '+ str(file_containing_start_pattern.strip()))
                        copy = True
                        outfile.write(line)
                        continue
                    elif end_read in line:
                        copy = False
                        logging.info('Found End in '+ str(file_containing_start_pattern.strip()))
                        outfile.write(line)
                        logging.info("Successfully parsed data from Start Demarcation to End Demarcation. Parsed output file in "+outputfile+"\n")
                        break
                    elif copy:
                        outfile.write(line)


class Parsing_Level_2:

    ''' Parsing Level 2 class '''

    def check_metadata_file(self):
        logging.info("Check if there are any queries left for parsing from last run")
        if os.path.exists(temp_query_breakdown_metadata):
            with open(temp_query_breakdown_metadata,'r') as file:
                lines=file.read().splitlines()
                last_line=lines[-1]
                _count_=int(last_line.split("::")[0]) + 1
        else:
            _count_=1
        return _count_


    def update_metadata_file(self):
        ''' Fetch out not parsed queries from metadata file which will be picked up in next run '''
        if os.path.isfile(parsed_metadata_file):
            with open(parsed_metadata_file,'r') as f1, open(temp_query_breakdown_metadata,'r') as f2, open(not_parsed_queries,'a') as f3:
                count=1
                for line1 in f2.readlines():
                    flag=0
                    query_id=line1.split("::")[0]
                    f1.seek(0)
                    for line2 in f1.readlines():
                        query_id_2=line2.split("::")[0]
                        if query_id == query_id_2:
                            flag=1
                            break
                        else:
                            continue
                    if flag == 0:
                        line3=line1.replace(query_id, str(count))
                        f3.write(line3)
                        count+=1
        else:
            with open(temp_query_breakdown_metadata,'r') as f2, open(not_parsed_queries,'a') as f3:
                count=1
                for line1 in f2.readlines():
                    flag=0
                    query_id=line1.split("::")[0]
                    line3=line1.replace(query_id, str(count))
                    f3.write(line3)
                    count+=1

    def fetch_select_query(self,_count_):
        ''' Create the metadata file from the collected select queries to track the parsing '''
        print time.strftime("%d-%m-%Y_%H:%M:%S")+" : Creating metadata file to track parsing {}".format(temp_query_breakdown_metadata)
        logging.info("Creating metadata file to track parsing {}".format(temp_query_breakdown_metadata))
        with open(input_file, 'r') as file, open(temp_query_breakdown_metadata, 'a') as metadata_file, open(tables_to_be_included, 'r') as tables_list_file:
            global _tables_
            _tables_=tables_list_file.read().splitlines()
            for line in file.readlines():
                string_split=line.split(",")
                _is_digit_=bool(re.match('^[0-9]+$', string_split[4]))
                if _is_digit_:
                    _line_split_=line.split(",", 5)
                    _query_=_line_split_[5]
                else:
                    _line_split_=line.split(",", 4)
                    _query_=_line_split_[4]
                query_id=str(_count_)
                metadata_file.write(query_id+"::"+_query_.strip('\n')+"::"+"NOT PARSED\n")
                _count_+=1

    def check_table_type(self,table_name, pm_counterName):
        ''' Update parsed output file with table name and counter name details '''
        partition_number=table_name.split('_')[-1]
        _is_partition_=bool(re.match('^[0-9]+$', partition_number))
        if _is_partition_:
            _table_type_="BASE"
        else:
            _table_type_="VIEW"
        _date_=time.strftime("%d-%m-%Y")
        with open(temp_parsed_output_file,'a') as temp_parse_level2_file:
            temp_parse_level2_file.write(table_name.strip('\n')+"::"+_table_type_+"::"+pm_counterName.strip('\n')+"::"+_date_+"\n")


    def get_multiple_select_queries(self,_line1_):
        ''' Segregate joint select queries in single query '''
        match_count=len(re.findall("select", _line1_))
        i=1
        index_value=0
        index_list=[]
        while i <= match_count:
            _index_=_line1_.find("select", index_value)
            index_list.append(_index_)
            index_value=_index_ + 1
            i+=1
        length=len(index_list)
        select_list=[]
        if length > 1:
            l=0
            while l < length:
                if l == (length - 1):
                    a=index_list[l]
                    select_query=_line1_[a:].strip()
                else:
                    a, b=index_list[l], index_list[l+1]
                    select_query=_line1_[a:b].strip()
                select_list.append(select_query)
                l+=1
        else :
            select_list.append(_line1_)
        return select_list

    def get_table_name(self,rawList_1):
        ''' Get the table name in the query '''
        tab_name=""
        for _char_ in ['"','dc.','dim.','\'','(',')','dcpublic.','dcbo.']:
            if _char_ in rawList_1:
                rawList_1=rawList_1.replace(_char_, '')
        rawList_2=rawList_1.strip().split()
        for t_name in rawList_2:
            if any(t in t_name for t in _tables_) and all(tab not in t_name for tab in tables_to_exclude):
                tab_name=t_name.upper().strip()
                return tab_name

    def get_table_specific_counters(self,master_file_list,table_name):
        table_specific_counters=[]
        for master_data in master_file_list:
            tp_name=master_data.split('::')[0]
            if tp_name.upper() in table_name:
                counterName=master_data.split('::')[1]
                table_specific_counters.append(counterName)
        return table_specific_counters

    def parse_tables_counters(self):
        ''' Parsing getched queries further to get table and counter information '''
        print time.strftime("%d-%m-%Y_%H:%M:%S")+" : Parsing Tables and PM counters from select queries"
        logging.info("Parsing Tables and PM counters from select queries")
        with open(temp_query_breakdown_metadata,'r') as metadata_file, open(counter_names_file,'r') as counters_info_file, open(all_columns_names_file,'r') as all_columns_info_file, open(master_file,'r') as master_file_for_counters_info:
            counter_names_list=counters_info_file.read().splitlines()
            all_columns_names_list=all_columns_info_file.read().splitlines()
            master_file_list=master_file_for_counters_info.read().splitlines()
            global failed_queries
            failed_queries=0
            global tables_to_exclude
            tables_to_exclude=['dc_z_alarm', 'dc_e_bulk_cm', 'dim_']

            for _lines_ in metadata_file.readlines():
                _line_=_lines_.split("::")[1]
                _line1_=_line_.lower()
                invalid_column=0
                invalid_column_list=[]
                # Clean temporary parsed output file for new query
                if os.path.exists(temp_parsed_output_file):
                    os.remove(temp_parsed_output_file) 

                # segregate if joint select queries are present
                select_list_1=self.get_multiple_select_queries(_line1_)
                select_list_2=[]
                for item in select_list_1:
                    for ch in ['partitions','"','union ','union all','all ','\'','and ','sum(','min(','max(','avg(','if(','if ','(',')']:
                        if ch in item:
                            item=item.replace(ch, '')
                    select_list_2.append(item)
                select_unique=[]
                for query in select_list_2:
                    flag=0
                    if "from" in query:
                        a=query.find("from")
                        for t in _tables_:
                            if t in query:
                                table_index=query.find(t, a)
                                space_index=query.find(" ", table_index+1)
                                match_query=query[:space_index]
                                for var in select_unique:
                                    if match_query in var:
                                        flag=1
                                        break
                                if flag == 0:
                                    select_unique.append(query)
                            else:
                                continue

                # Parse the segregated queries one by one
                for _line_1_ in select_unique:
                    no_table=0
                    table_name=""
                    pm_counterName=""

                    # To handle "select *" and "select count(*)" queries
                    select_star=['select *', 'select count*', 'select count']
                    #select_top=['select top', '*']
                    select_top=bool(re.match(r'select top \d+\ \*',_line_1_))
                    #if any(k in _line_1_ for k in select_star) or all(st in _line_1_ for st in select_top):
                    if any(k in _line_1_ for k in select_star) or select_top:
                        counter_flag=1
                        ''' --- Select * and Select count(*) handling --- '''
                        pm_counterName="ALL"
                        c, d = _line_1_.find("from "), _line_1_.find("where")
                        # getting the position of 'select' and from to get the counters
                        if d == -1:
                            rawList_1=_line_1_[c + 5:].strip()
                        else:
                            rawList_1=_line_1_[c + 5:d].strip()
                        for _char_ in ['"','dc.','dim.','\'','and ','min(','max(','avg(','sum(','dcpublic.','dcbo.','(',')']:
                            if _char_ in rawList_1:
                                rawList_1=rawList_1.replace(_char_, '')
                        rawList_2=rawList_1.strip().split(',')
                        for t_name in rawList_2:
                            rawList_3=t_name.strip().split()
                            for tab_name in rawList_3:
                                table_name=tab_name.upper().strip()
                                if any(t.upper() in table_name for t in _tables_) and all(tab.upper() not in table_name for tab in tables_to_exclude):
                                    for master_data in master_file_list:
                                        tp_name=master_data.split('::')[0]
                                        if tp_name.upper() in table_name:
                                            # To update counter name in temporary parsed file
                                            self.check_table_type(table_name, pm_counterName)
                                            break
                                else:
                                    continue
                    else:
                        ''' --- Generic Select query handling --- '''
                        # getting the table name with alias name
                        alias_flag=0
                        c, d = _line_1_.find("from "), _line_1_.find("where")
                        if d == -1:
                            rawList_1=_line_1_[c + 5:].strip()
                        else:
                            rawList_1=_line_1_[c + 5:d].strip()
                        if "as" in rawList_1:
                            tableList=[]
                            alias_flag=1
                            for _char_ in ['"','dc.','dim.','\'', 'as ','and ','min(','max(','avg(','sum(','dcpublic.','dcbo.','(',')']:
                                if _char_ in rawList_1:
                                    rawList_1=rawList_1.replace(_char_, '')
                            tableList=rawList_1.split(",")
                        #Get the index of "select" to "from" to find pm counters
                        a, b = _line_1_.find('select '), _line_1_.find('from')
                        rawList=_line_1_[a + 7:b].strip()
                        for ch in ['distinct ','distinct(','"','sum(','dc.','dim.','*','as ','\'','if(','if ','count ','count(','results ','result ','and ','min(','max(','avg(','dcpublic.','dcbo.','(',')',' in ',' else ','ifnull','null','/','yyyy-mm-dd','e2e--mme','-','{','}',' end','substring','charindex','then ']:
                            if ch in rawList:
                                if ch == "*" or ch == " in " or ch == "null" or ch == "then ":
                                    rawList=rawList.replace(ch, ' ')
                                elif ch == " else " or ch == "-" or ch == "/" or ch == "ifnull":
                                    rawList=rawList.replace(ch, ',')
                                else:
                                    rawList=rawList.replace(ch, '')
                        counterList_1=rawList.split(",")
                        counterList=[]
                        eliminate_dec=[]

                        # Eliminate the multipliers e.g. 0.08*<counter/table name>
                        r1=re.compile(r'\d+\.\d+')
                        exclude_decimal_1=list(filter(r1.findall, counterList_1))
                        if len(exclude_decimal_1) == 0:
                            counterList=counterList_1
                        else:
                            for exc_dec in exclude_decimal_1:
                                exclude_decimal=re.findall(r'\d+\.\d+',exc_dec)
                                for excl_int in exclude_decimal:
                                    eliminate_dec.append(excl_int)
                            for item_list in counterList_1:
                                for elim_dec in eliminate_dec:
                                    if elim_dec in item_list.strip():
                                        item_list=item_list.strip().replace(elim_dec, '')
                                counterList.append(item_list.strip())

                        # In case, aliases are assigned for tables without using "as" keyword
                        #r2=re.compile(r'd\d+\.')
                        r2=re.compile(r'\.')
                        alias_name=list(filter(r2.findall, counterList))
                        if len(alias_name) > 0 and alias_flag == 0 :
                            tableList=[]
                            for alias_nm in alias_name:
                                if any(raw_item in alias_nm for raw_item in rawList_1) and all(t not in alias_nm for t in _tables_):
                                    alias_flag=1
                                    for _char_ in ['"','dc.','dim.','\'', 'as ','and ','min(','max(','avg(','sum(','dcpublic.','dcbo.','(',')']:
                                        if _char_ in rawList_1:
                                            rawList_1=rawList_1.replace(_char_, '')
                                    if rawList_1 not in tableList:
                                        tableList=rawList_1.split(",")

                        keywords=['case', 'when']
                        # Check if invalid_counter is present in the query
                        for item in counterList:
                            if all(k in item.strip() for k in keywords):
                                continue
                            elif any(nc.lower() in item.strip() for nc in all_columns_names_list):
                                continue
                            elif item.strip().isdigit() or not item.strip():
                                continue
                            else:
                                if all(tab not in rawList_1 for tab in tables_to_exclude):
                                    invalid_column=1
                                    invalid_column_list.append(item)

                        for item in counterList:
                            if "." in item.strip() and "+" in item.strip():
                                i=counterList.index(item)
                                counterList[i]=item.strip().replace('+',' ')
                        if invalid_column == 0:
                            # Parse further to collect counter and table names
                            for item in counterList:
                                counter_present=0
                                if any(c.lower() in item.strip() for c in counter_names_list):
                                    #counter_flag=1
                                    if all(k in item.strip() for k in keywords):
                                        continue
                                    elif "+" in item.strip():
                                        # Get Table name from query
                                        table_name=self.get_table_name(rawList_1)
                                        if not table_name:
                                            no_table=1
                                            break

                                        # Fetch table specific counter list from master file
                                        table_specific_counters=self.get_table_specific_counters(master_file_list,table_name)

                                        temp_list=item.strip().split("+")
                                        for i in temp_list:
                                            i_split=i.split()
                                            for i_sep in i_split:
                                                counter_present=0
                                                if any(c.lower() in i_sep.strip() for c in table_specific_counters):
                                                    temp_list_1=i_sep.strip().split()
                                                    for temp in temp_list_1:
                                                        counter_present=0
                                                        if table_specific_counters:
                                                            for cn in table_specific_counters:
                                                                if cn.lower() == temp.strip():
                                                                    pm_counterName=temp.strip()
                                                                    counter_present=1
                                                        else:
                                                            break
                                                        if counter_present:
                                                            # To update counter name in temporary parsed file
                                                            self.check_table_type(table_name, pm_counterName)
                                                        else:
                                                            continue
                                                else:
                                                    continue
                                    elif "." in item.strip():
                                        table_name=""
                                        ''' Multiple Table scenario '''
                                        temp_list=item.split(".")
                                        # Reading Alias used for Table Name
                                        space_sep_alias=temp_list[0].split()
                                        for alias_name in space_sep_alias:
                                            if alias_flag == 1 and all(t not in alias_name for t in _tables_) and all(tex not in alias_name for tex in tables_to_exclude):
                                                for alias_ in tableList:
                                                    if alias_name in alias_:
                                                        table_alias=alias_.strip().split()
                                                        table_name=table_alias[0].upper().strip()
                                            else:
                                                if any(tex in alias_name for tex in tables_to_exclude):
                                                    table_name="exclude_table"
                                                elif any(t in alias_name for t in _tables_):
                                                    table_name=alias_name.upper().strip()
                                        if table_name == "exclude_table":
                                            continue
                                        elif not table_name:
                                            no_table=1
                                            break

                                        # Fetch table specific counter list from master file
                                        table_specific_counters=self.get_table_specific_counters(master_file_list,table_name)

                                        space_sep_counter=temp_list[1].split()
                                        for item_sep in space_sep_counter:
                                            if table_specific_counters:
                                                for cn in table_specific_counters:
                                                    if cn.lower() == item_sep.strip():
                                                        pm_counterName=item_sep.strip()
                                                        counter_present=1
                                            else:
                                                break

                                        if counter_present:
                                            if table_name:
                                                # To update counter name in temporary parsed file
                                                self.check_table_type(table_name, pm_counterName)
                                                #break
                                            else:
                                                no_table=1
                                                break
                                        else:
                                            continue
                                    else:
                                        # Get Table name from query
                                        table_name=self.get_table_name(rawList_1)
                                        if not table_name:
                                            no_table=1
                                            break

                                        # Fetch table specific counter list from master file
                                        table_specific_counters=self.get_table_specific_counters(master_file_list,table_name)

                                        space_sep_counter=item.strip().split()
                                        for item_sep in space_sep_counter:
                                            if table_specific_counters:
                                                for cn in table_specific_counters:
                                                    if cn.lower() == item_sep.strip():
                                                        ''' Single Table scenario '''
                                                        pm_counterName=item_sep.strip()
                                                        counter_present=1
                                            else:
                                                break

                                        if counter_present:
                                            if table_name:
                                                # To update counter name in temporary parsed file
                                                self.check_table_type(table_name, pm_counterName)
                                                #break
                                            else:
                                                no_table=1
                                                break
                                        else:
                                            continue
                                else:
                                    continue
                                if no_table:
                                    break
                if invalid_column == 1:
                    failed_queries=1
                    failed_line=_lines_.replace('NOT PARSED', 'FAILED').strip("\n")
                    failed_line=failed_line+"::"
                    for column_ in invalid_column_list:
                        failed_line=failed_line+column_+" ,"
                    failed_line1=failed_line.strip(',')+"\n" 
                    with open(temp_failed_metadata_file,'a') as temp_failed_queries_file:
                        temp_failed_queries_file.write(failed_line1)
                else:
                    if os.path.exists(temp_parsed_output_file):
                        with open(temp_parsed_output_file,'r') as temp_parse_level2_file, open(parsed_output_file,'a') as parse_level2_file:
                            parse_output_list=temp_parse_level2_file.read().splitlines()
                            for parsed_output in parse_output_list:
                                parse_level2_file.write(parsed_output+"\n")
                    parsed_line=_lines_.replace('NOT PARSED', 'PARSED')
                    with open(parsed_metadata_file,'a') as metadata_file_after:
                        metadata_file_after.write(parsed_line)
                time.sleep(0.1)

class User_Display:

    ''' User Display class '''

    def calc_total(self,file):
        raw_list=[]
        for x in open(file.strip()).readlines():
                #print(x)
                raw_list.append(x.strip('\n').split('::')[2])
        #print(raw_list)
        raw_list_int = [int(i) for i in raw_list]
        total_count=sum(Decimal(i) for i in raw_list_int)
        return total_count
    
    def convert_csv(self,file):
        csv_file=file+".csv"
        with open(file, 'r') as in_file:
            stripped = (line.strip() for line in in_file)
            lines = (line.split("::") for line in stripped if line)
            with open(csv_file, 'w') as out_file:
                writer = csv.writer(out_file)
                #writer.writerow(('TableName', 'CounterName'))
                writer.writerows(lines)
        #print(csv_file)
        return csv_file

    def print_summary_table(self,total_uniq_count,total_unaccessed_counter,total_uniq_accessed):
               
        data = [['PARAMETER', 'VALUE'],
                ['Total Unique Counters', total_uniq_count],
                ['Total Unique Accessed Counters', total_uniq_accessed],
                ['Total Unique Unaccessed Counters', total_unaccessed_counter]]
        
        dash = '-' * 100
        
        for i in range(len(data)):
            if i == 0:
              print(dash)
              print('{:<80s}{:>10s}'.format(data[i][0],data[i][1]))
              print(dash)
            else:
              print('{:<80s}{:>10d}'.format(data[i][0],data[i][1]))

    def feature_wise_table(self, aggregated_counters_csv): 
        print ("\n")
        print ("------------------------------------------------------------------------------------------------------------ ")
        print (" Feature_Name                                       Accessed_Counters                 Unaccessed_Counters ")
        print ("------------------------------------------------------------------------------------------------------------ ")
        for r in open(feature_wise_summary_file.strip()).readlines():
            feature= r.strip()
            unaccessed_counters=str(subprocess.check_output('''cat %s | grep "%s" |grep -w "0,NA" | wc -l'''%(aggregated_counters_csv,feature), shell= True).strip())
            accessed_counters=str(subprocess.check_output('''cat %s | grep "%s" |grep -v "0,NA" | wc -l'''%(aggregated_counters_csv,feature), shell= True).strip())
            data = [feature,accessed_counters,unaccessed_counters]
            print('{:<50s}{:>10s}{:>40s}'.format(data[0],data[1],data[2]))
			
    def user_display(self):

        #aggregate values
        obj_cntr=[]
        for r in open(aggregated_counters.strip()).readlines():
            file_obj_cntr=r.strip('\n').split('::')
            obj_cntr.append(file_obj_cntr)

        total_unaccessed_counter = sum(1 for line in open(unused_counter_list_file))
        total_uniq_count=len(obj_cntr)
        total_uniq_accessed=len(obj_cntr) - total_unaccessed_counter

        
        # add header
        with open(aggregated_counters, "r+") as f: s = f.read(); f.seek(0); f.write("# Table_Name::Counter_Name::Total Access_Count::Last_Access_Date::Feature_Name #\n" + s)
        with open(counter_data_per_date, "r+") as f: s = f.read(); f.seek(0); f.write("# Table_Name::Counter_Name::Access_Count::Access_Date::Feature_Name #\n" + s)
        with open(unused_counter_list_file, "r+") as f: s = f.read(); f.seek(0); f.write("# Table_Name::Counter_Name::Access_Count::Access_Date::Feature_Name #\n" + s)
        
        # Convert to CSV
        unused_counter_list_file_csv=self.convert_csv(unused_counter_list_file)
        aggregated_counters_csv=self.convert_csv(aggregated_counters)
        counter_data_per_date_csv=self.convert_csv(counter_data_per_date)


        #print summary and add this to logfile
        self.print_summary_table(total_uniq_count,total_unaccessed_counter,total_uniq_accessed)
        self.feature_wise_table(aggregated_counters_csv)
        report_path = "\33[32m{}\033[0m".format("\n--------- "+timeStr+": Report Details :---------\n"+'Aggregated access count across the selected Time Range:'+aggregated_counters_csv+'\nDaywise statistics across the selected Time Range:'+counter_data_per_date_csv+'\nUnaccessed counter data across the selected Time Range:'+unused_counter_list_file_csv+'\nSummary Report:'+sys.argv[2]+'\n')
        logging.info(report_path)
        print report_path
        
        print("--------------------------------------------------------------------------------------------------------------\n")


                        
def exit_gracefully(signum, frame):
    """
        restore the original signal handler as otherwise evil things will happen
        in raw_input when CTRL+C is pressed, and our signal handler is not re-entrant
    """
    print "Script Exiting Abnormally"
    exit(1)


if __name__== "__main__":
    original_sigint = signal.getsignal(signal.SIGINT)
    signal.signal(signal.SIGINT, exit_gracefully)
    format_str = '%(levelname)s: %(asctime)s: %(message)s'
    logging.basicConfig(level=logging.DEBUG, filename=sys.argv[2], format=format_str)

    parsing_level_type=sys.argv[3]
    if parsing_level_type == "parsing_level_1":
        print("\33[33m{}\033[0m".format("******************** {} : Entering Parsing Level 1 ********************".format(time.strftime("%d-%m-%Y_%H:%M:%S"))))
        logging.info("******************** Entering Parsing Level 1 ********************")
        '''Parsing Level 1'''
        #changing to the parent directory of the node
        os.chdir(sys.argv[1])
        #temporary work directory
        temp_work_dir=sys.argv[5]
       
        #create parsed output file along with instance no.
        timeStr = time.strftime("%d-%m-%Y_%H:%M:%S")
        parsed_output_file =sys.argv[1]+"/files_to_parse_L1/"+timeStr+"_Parse_Level1.log"
        if os.path.exists('demarcation_metadata_file'):
            instance=subprocess.check_output('cat demarcation_metadata_file',shell=True).strip().split('_')[-1]
            outputfile=parsed_output_file+'_'+instance
        else:
            outputfile=parsed_output_file+'_0'

        #create temp folders 
        temp_folder='/eniq/backup/counter_parse_tmp/'
        flag_file=sys.argv[1]+"/.first_occurance_instance_one"
        #if not os.path.exists('/var/tmp/parse_tmp/'):
            #os.mkdir('/var/tmp/parse_tmp/')
        if not os.path.exists(temp_folder):
            os.mkdir(temp_folder)

        # saving parse file name in temp file
        parse_1=Parsing_Level_1()
        parse_1.parse_level_1()
        parsing_level_1_output = open(temp_work_dir+"/parse_1_output", "w")
        parsing_level_1_output.write(outputfile)
        parsing_level_1_output.close()

        # Cleanup
        if os.path.exists(temp_folder):
            shutil.rmtree(temp_folder)

    elif parsing_level_type == "parsing_level_2":
        '''Parsing Level 2'''
        input_file=sys.argv[4]
        temp_output_file_location=sys.argv[1]
        temp_work_dir=sys.argv[5]

        # Directories required for parsing level 2
        counter_tool_parent_dir="/eniq/log/sw_log/iq/CounterTool"
        counter_tool_work_dir=counter_tool_parent_dir+"/working_directory"
        counter_tool_failed_dir=counter_tool_parent_dir+"/failed_queries"

        # Files required for parsing level 2
        timeStr=time.strftime("%d-%m-%Y_%H:%M:%S")
        parsed_output_file=temp_output_file_location+"/Parse_Level2.log_"+timeStr
        temp_parsed_output_file=temp_work_dir+"/temporary_parsed_output_file.log_"+timeStr
        temp_failed_metadata_file=temp_work_dir+"/temporary_failed_parsed_queries.txt_"+timeStr
        query_breakdown_metadata=counter_tool_work_dir+"/query_breakdown.txt"
        temp_query_breakdown_metadata=temp_work_dir+"/query_breakdown.txt_"+timeStr
        parsed_metadata_file=temp_work_dir+"/metadata_file.txt_"+timeStr
        failed_metadata_file=counter_tool_failed_dir+"/failed_parsed_queries.txt"
        not_parsed_queries=temp_work_dir+"/not_parsed_metadata.txt_"+timeStr
        counter_names_file=temp_work_dir+"/all_counters.txt" #all_counters_from_master_file_path
        all_columns_names_file=temp_work_dir+"/all_columns.txt" #all_columns_from_repdb
        master_file=temp_work_dir+"/master_file_for_counters_info_final.txt" #master_file
        tables_to_be_included=counter_tool_parent_dir+"/tables_to_be_considered.txt"
        parallel_threads=sys.argv[6]
        runtime_file=parallel_threads+"/parallel_thread_"+timeStr

        if os.path.exists(parallel_threads):
            os.system('touch {}'.format(runtime_file))
            if os.path.exists(runtime_file):
                os.system('cat {}'.format(runtime_file))

        # Start parsing
        parse_2=Parsing_Level_2()

        if os.path.exists(query_breakdown_metadata):
            copy2(query_breakdown_metadata,temp_query_breakdown_metadata)
            os.remove(query_breakdown_metadata)

        # Check for not parsed/failed queries from last run
        query_count=parse_2.check_metadata_file()

        # Collect select queries from parsing level 1 output file for further breakdown
        parse_2.fetch_select_query(query_count)
        try:
            parse_2.parse_tables_counters()
        except:
            parse_2.update_metadata_file()
            #os.remove(query_breakdown_metadata)
            copy2(not_parsed_queries,query_breakdown_metadata)
            os.remove(runtime_file)
            for files in [not_parsed_queries,parsed_metadata_file]:
                if os.path.exists(files):
                    os.remove(files)
            logging.error("Issue encountered while parsing the table and counter details. Remaining select queries will be parsed in next run")
            exit(1)

        # Queries containing columns names which are not specified in master file are found
        if failed_queries == 1:
            # Take backup of input and output file in case of failure
            if os.path.exists(temp_failed_metadata_file):
                with open(temp_failed_metadata_file,'r') as temp_failed_queries_file, open(failed_metadata_file,'a') as failed_queries_file:
                    failes_queries_list=temp_failed_queries_file.read().splitlines()
                    for failed_queries_line in failes_queries_list:
                        failed_queries_file.write(failed_queries_line+"\n")

            copy2(input_file,counter_tool_failed_dir)

            logging.error("Failed to parse few queries. Please find the failed queries in {}\n".format(failed_metadata_file))

        # Exit the code due to errors detected
        if failed_queries == 1:
            for files in [not_parsed_queries,parsed_metadata_file]:
                if os.path.exists(files):
                    os.remove(files)
            os.remove(runtime_file)
            exit(1)

        # Normal scenario
        for files in [not_parsed_queries,parsed_metadata_file]:
            if os.path.exists(files):
                os.remove(files)
        logging.info("Parsing Level 2 completed successfully for this thread")
        os.remove(runtime_file)

    elif parsing_level_type == "user_display":
        '''User Display'''

        timeStr = time.strftime("%d-%m-%Y_%H-%M-%S")
        statistics_path="/eniq/log/sw_log/iq/CounterTool/Statistics/"
        if not os.path.exists(statistics_path):
            os.mkdir(statistics_path)

        #Files for the reports
        unused_counter_list_file=statistics_path+timeStr+"_unused_counter_list_file"
        aggregated_counters=statistics_path+timeStr+"_aggregated_counters"
        counter_data_per_date=statistics_path+timeStr+"_counter_data_per_date"
        feature_wise_summary_file=statistics_path+timeStr+"_feature_wise_summary_file" 
 
        copy2(sys.argv[5],unused_counter_list_file)
        copy2(sys.argv[4],counter_data_per_date)
        copy2(sys.argv[1],aggregated_counters)
        copy2(sys.argv[6],feature_wise_summary_file)


        user_disp=User_Display()
        user_disp.user_display()
        
        #cleanup
        for files in [unused_counter_list_file,counter_data_per_date,aggregated_counters,feature_wise_summary_file]:
            if os.path.exists(files):
                os.remove(files)

exit(0)
