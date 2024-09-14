#!/bin/bash
cat  /proc/meminfo | grep HugePages_Total
sudo cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bkp_2021012501
sudo cp /etc/default/grub /etc/default/grub_2021012501
sudo sed -i 's/TRIPLEO_HEAT_TEMPLATE_KERNEL_ARGS=" default_hugepagesz=1GB hugepagesz=1G hugepages=320 iommu=pt intel_iommu=on transparent_hugepage=never isolcpus=2-19,20-39,42-59,60-79 processor.max_cstate=0 intel_idle.max_cstate=0 spectre_v2=off nopti "/TRIPLEO_HEAT_TEMPLATE_KERNEL_ARGS=" default_hugepagesz=1GB hugepagesz=1G hugepages=352 iommu=pt intel_iommu=on transparent_hugepage=never isolcpus=2-19,20-39,42-59,60-79 processor.max_cstate=0 intel_idle.max_cstate=0 spectre_v2=off nopti "  /g' /etc/default/grub
diff /etc/default/grub /etc/default/grub_2021012501
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grep -i linux16 /boot/grub2/grub.cfg
