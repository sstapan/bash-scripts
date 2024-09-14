#!/bin/bash
source /home/stack/overcloudrc
while read line; 
do
  declare -i x=1
  for word in $line
  do
    if [ $x -eq 1 ];then
      flavorselect=$word
    elif [ $x -eq 2 ];then
      flavorname=$word
    elif [ $x -eq 3 ];then
      ramgb=$word
    elif [ $x -eq 4 ];then
      cores=$word
	elif [ $x -eq 5 ];then
      disk=$word
	elif [ $x -eq 6 ];then
      numanode=$word
    else
      echo "fatal error, check text file, probable there are extra entries"
    fi
    x+=1
  done
  numacores=$(($cores/2))
  cpumaxcores=$(($cores/2))
  rammb=$(($ramgb*1024))
  numarammb=$(($rammb/2))
  if [ $numanode -eq 0 ];then
    numa="_NUMA_0"
    openstack flavor create --ram $rammb --disk $disk --vcpus $cores --property hw:cpu_max_sockets=1 --property hw:cpu_policy=dedicated --property hw:mem_page_size=large --property hw:numa_cpus.0=$(seq -s "," 0 $(($cores-1))) --property hw:numa_mem.0=$rammb --property hw:numa_mempolicy=strict --property hw:numa_nodes=1 $flavorname$numa --public
  elif [ $numanode -eq 1 ];then
    numa="_NUMA_1"
    openstack flavor create --ram $rammb --disk $disk --vcpus $cores --property hw:cpu_max_sockets=1 --property hw:cpu_policy=dedicated --property hw:mem_page_size=large --property hw:numa_cpus.1=$(seq -s "," 0 $(($cores-1))) --property hw:numa_mem.1=$rammb --property hw:numa_mempolicy=strict --property hw:numa_nodes=1 $flavorname$numa --public
  elif [ $numanode -eq 2 ];then
	numa="_BOTH_NUMA"
    openstack flavor create --ram $rammb --vcpus $cores --property hw:cpu_max_sockets=2 --property hw:cpu_policy=dedicated --property hw:mem_page_size=large --property hw:numa_cpus.0=$(seq -s "," 0 $(($numacores-1))) --property hw:numa_mem.0=$numarammb --property hw:numa_cpus.1=$(seq -s "," $numacores $(($cores-1))) --property hw:numa_mem.1=$numarammb --property hw:numa_mempolicy=strict --property hw:numa_nodes=2 $flavorname$numa --public
  elif [ $numanode -eq 3 ];then
    if [ $cores -le 4 ];then
      openstack flavor create --ram $rammb --disk $disk --vcpus $cores --property hw:cpu_policy=dedicated --property hw:mem_page_size=large --property hw:numa_mempolicy=strict --property hw:numa_nodes=2 --property hw:numa_cpus.0=$(seq -s "," 0 $(($numacores-1))) --property hw:numa_mem.0=$numarammb --property hw:numa_cpus.1=$(seq -s "," $numacores $(($cores-1))) --property hw:numa_mem.1=$numarammb --property hw:cpu_max_sockets=2 --property hw:cpu_max_cores=$cpumaxcores --property hw:cpu_max_threads=1 $flavorname --public
    else
      openstack flavor create --ram $rammb --disk $disk --vcpus $cores --property hw:cpu_policy=dedicated --property hw:mem_page_size=large --property hw:numa_mempolicy=strict --property hw:numa_nodes=2 --property hw:numa_cpus.0=$(seq -s "," 0 $(($numacores-1))) --property hw:numa_mem.0=$numarammb --property hw:numa_cpus.1=$(seq -s "," $numacores $(($cores-1))) --property hw:numa_mem.1=$numarammb --property hw:cpu_max_sockets=2 --property hw:cpu_max_cores=$(($cpumaxcores/2)) --property hw:cpu_max_threads=2 $flavorname --public
    fi
  else
    echo "wrong numa details"
  fi
done < /home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/addtnlPostDepFiles/selectFlavor.txt