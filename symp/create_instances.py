#!/usr/bin/python

import sys
import getopt
import requests
import json
import os
import time
import symphony_client as symp

def _initClient(url, username, password, domain, project, secure=True):
    session = None
    if secure:
        # skip SSL certificate verification
        session = requests.Session()
        session.verify = False
    
    try:
        # Create Symp client
        client = symp.Client(url=url, session=session)
        client.login(username=username,password=password,domain=domain,project=project)
    except:
        print("Couldn't access neokarm cluster url {}.".format(url))
        sys.exit(1)

    return client


def _createVpc(client, cidr_block):
    try:
        vpc_id = client.vpcs.create(cidr_block=cidr_block, name="sympVPC")["id"]
        time.sleep(8)
        while client.vpcs.get(vpc_id=vpc_id)["state"] != "available":
            time.sleep(1)
        print("vpc {} has been created.".format(vpc_id))
    except:
        print("unable to create VPC")
        sys.exit(1)

    return vpc_id

def _createSubnet(client, vpc_id, cidr_block):
    try:
        net_id = client.vpcs.networks.create(vpc_id=vpc_id, cidr_block=cidr_block)["id"]
        time.sleep(8)
        while client.vpcs.networks.get(network_id=net_id)["state"] != "available":
            time.sleep(1)
        print("subnet {} has been created.".format(net_id))
    except:
        print("unable to create a subnet")
        sys.exit(1)

    return net_id

def _createInstances(client, instances_count, image_id, net_id):
    instance = ""
    instanceIds = list()
    try:
        for i in range(instances_count):
            vm_name = "vm{}".format(str(i))
            instance_id = client.vms.create(name=vm_name,image_id=image_id,net_id=net_id)["id"]
            print("instance {} has been created.".format(instance_id))
            instanceIds.append(instance_id)
    except: 
        print("Couldn't create instances")
        sys.exit(1)
    try: 
        time.sleep(10)
        for id in instanceIds:
            while client.vms.get(id)["status"] == 'spawning':
                time.sleep(1)
            instance = client.vms.start(vm_id=id)
    except:
        print("Couldn't start instances")
        sys.exit(1)
    

def main(argv):
    url = ''
    username = ''
    password = ''
    domain = ''
    project = ''
    instances_count = 3
    image_id = ''
    # The vpc_subnet has to be in the vpc cidr_block range
    vpc_cidr_block = ''
    vpc_subnet = ''
    
    client = _initClient(
        url=url,
        username=username,
        password=password,
        domain=domain,
        project=project,
        )

    vpc_id =_createVpc(
        client=client,
        cidr_block=vpc_cidr_block
        )

    net_id = _createSubnet(
        client=client,
        vpc_id=vpc_id,
        cidr_block=vpc_subnet
        )

    _createInstances(
        client = client, 
        instances_count = instances_count,
        image_id = image_id,
        net_id=net_id    
        )
       

# Main
if __name__ == "__main__":
   main(sys.argv[1:])