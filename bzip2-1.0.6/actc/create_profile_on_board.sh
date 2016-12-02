#!/bin/bash

# Authors: Jeroen Van Cleemput, Bart Coppens

set -e
set -u

#---------------
#Settings
#---------------
ssh_port=917
#ssh_host=tyr.elis.ugent.be
ssh_host=172.18.20.143
ssh_user=bcoppens
#ssh_key="-i ..."
ssh_key=""
ssh_path="/home/bcoppens/bzip2_metrics/"

#---------------
#Configuration
#---------------
aid=$1
src=$2

ssh_port_and_optional_key="${ssh_port} ${ssh_key}"
ssh_options="-p ${ssh_port_and_optional_key}"
scp_options="-P ${ssh_port_and_optional_key}"

application_files=bzip2_input.txt
application=bzip2

src_path="${src}"
dst_path="${src_path}/profiles/"

application_source="${application}.self_profiling"
profile_files="profiling_section.${application}.self_profiling"

run_command="cd $ssh_path; rm -f ${profile_files}; ./bzip2 --compress bzip2_input.txt; ./bzip2 --decompress bzip2_input.txt.bz2"

profile_to_plaintext=/opt/diablo/scripts/profiles/binary_profile_to_plaintext.py

#---------------
#Functions
#---------------
function info()
{
  echo "Source: ${src}"
  echo "AID: ${aid}"
}

function copy_to_board()
{
  #create target directory
  ssh ${ssh_options} ${ssh_user}@${ssh_host} "rm -rf ${ssh_path};  mkdir -p ${ssh_path}"

  #Copy helper files
  scp ${scp_options} -r ${application_files} ${ssh_user}@${ssh_host}:${ssh_path}

  #Copy application
  scp ${scp_options} -r ${src_path}/${application_source} ${ssh_user}@${ssh_host}:${ssh_path}/${application}
}

function run()
{
  #run the application on the board. This genereates a 'profiling_section.libdiamante.so.self_profiling' file on the board.
  ssh ${ssh_options} ${ssh_user}@${ssh_host} "${run_command}"
}

function retrieve_profiles()
{
  mkdir -p ${dst_path}
  scp ${scp_options} ${ssh_user}@${ssh_host}:${ssh_path}/${profile_files}  ${dst_path}/${profile_files}
  ${profile_to_plaintext} ${dst_path}/${profile_files} > ${dst_path}/${profile_files}.plaintext
}

info
copy_to_board
run
retrieve_profiles
