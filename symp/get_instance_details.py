#!/usr/bin/python

import sys
import getopt
import requests
import json
import os

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

def _getInstanceDetails(client, instance_id):
    try:
        instance = client.vms.get(instance_id)
    except:
        print("Couldn't get instance {}.".format(instance_id))
        sys.exit(1)

    return instance

def main(argv):
    instance_id = ''
    url = ''
    username = ''
    password = ''
    domain = ''
    project = ''

    client = _initClient(
        url=url,
        username=username,
        password=password,
        domain=domain,
        project=project,
        )

    print(
        json.dumps(
            _getInstanceDetails(
                client=client,
                instance_id=instance_id
                )
            )
        )

# Main
if __name__ == "__main__":
   main(sys.argv[1:])