#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# flake8: noqa

# Make sure pyudev is upgraded to at least 0.21

import sys
import os
import requests
import pyudev
import boto3
from retrying import retry
import logging
import logging.handlers


@retry(wait_exponential_multiplier=1000, wait_exponential_max=10000, stop_max_attempt_number=5)
def main(kernel_name):
    _log_setup()
    logging.info('[%s] New Device', kernel_name)
    serial = _get_device_serial(kernel_name)
    logging.info('[%s] Serial is %s', kernel_name, serial)
    instance_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
    availability_zone = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone')
    device_name = _get_device_name(instance_id.content.decode('utf-8'), availability_zone.content.decode('utf-8')[:-1], serial)
    logging.info('[%s] Device Name is %s', kernel_name, device_name)
    if device_name:
        print(os.path.relpath(device_name, '/dev'))


def _log_setup():
    log_handler = logging.handlers.RotatingFileHandler('/var/log/symphony_disk_mapper.log', maxBytes=20000, backupCount=5)
    logger = logging.getLogger()
    logger.addHandler(log_handler)
    logger.setLevel(logging.INFO)


def _get_device_serial(kernel_name):
    context = pyudev.Context()
    device = pyudev.Devices.from_name(context, 'block', kernel_name)
    serial = device.attributes.asstring('serial')
    return serial.replace('-', '')


def _get_device_name(instance_id, region, serial):
    client = boto3.client('ec2', region_name=region, endpoint_url='${ symphony_ec2_endpoint }')
    response = client.describe_instances(InstanceIds=[instance_id])
    block_devices = response['Reservations'][0]['Instances'][0]['BlockDeviceMappings']
    for block_device in block_devices:
        vol_id = block_device['Ebs']['VolumeId'].split('-')[1]
        if vol_id.startswith(serial):
            return block_device['DeviceName']
    return ''


if __name__ == '__main__':
    os.environ['AWS_CA_BUNDLE'] = '/etc/pki/tls/certs/ca-bundle.crt'
    os.environ['AWS_METADATA_SERVICE_TIMEOUT'] = '5'
    os.environ['AWS_METADATA_SERVICE_NUM_ATTEMPTS'] = '3'
    main(sys.argv[1])
