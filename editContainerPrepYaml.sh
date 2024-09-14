#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-08-21 ######
##################################################################################
sed -i "/ceph_alertmanager_image/c\      ceph_alertmanager_image: $1-prometheus-alertmanager" ~/containers-prepare-parameter.yaml
sed -i "/ceph_alertmanager_namespace/c\      ceph_alertmanager_namespace: $2:5000" ~/containers-prepare-parameter.yaml
sed -i "/ceph_grafana_image/c\      ceph_grafana_image: $1-rhceph-4-dashboard-rhel8" ~/containers-prepare-parameter.yaml
sed -i "/ceph_grafana_namespace/c\      ceph_grafana_namespace: $2:5000" ~/containers-prepare-parameter.yaml
sed -i "/ceph_image/c\      ceph_image: $1-rhceph-4-rhel8" ~/containers-prepare-parameter.yaml
sed -i "/ceph_namespace/c\      ceph_namespace: $2:5000" ~/containers-prepare-parameter.yaml
sed -i "/ceph_node_exporter_image/c\      ceph_node_exporter_image: $1-prometheus-node-exporter" ~/containers-prepare-parameter.yaml
sed -i "/ceph_node_exporter_namespace/c\      ceph_node_exporter_namespace: $2:5000" ~/containers-prepare-parameter.yaml
sed -i "/ceph_prometheus_image/c\      ceph_prometheus_image: $1-prometheus" ~/containers-prepare-parameter.yaml
sed -i "/ceph_prometheus_namespace/c\      ceph_prometheus_namespace: $2:5000" ~/containers-prepare-parameter.yaml
sed -i "/name_prefix/c\      name_prefix: $1-" ~/containers-prepare-parameter.yaml
sed -i "/    namespace/c\      namespace: $2:5000" ~/containers-prepare-parameter.yaml
