# Ansible configuration

## Pre-preparation for using ansible examples
1. `pip3 install boto`
2. Download symphony selfsigned certificate (selfsigned.pem) 
3. Edit boto configuration file (~/.boto)
```
[Boto]
is_secure = True
ca_certificates_file = /home/Downloads/selfsigned.pem
```
4. `pip install ansible`

## Work with repo files
1. Clone this repo and copy ec2.py and ec2.ini files into /etc/ansible directory
2.  Clone aws modules repo (you can do it from here https://github.com/ansible-collections/community.aws.git)
3. Edit ansible.cfg file
```
[defaults]
# some basic default values...
inventory = /etc/ansible/ec2.py 
ansible python module location = /usr/local/lib/python3.8/site-packages/ansible
private_key_file = /home/harel/keys.pem  #key to ssh hosts
library = /etc/ansible/community.aws/plugins/modules 
```
## Start working with inventory
1. Edit ec2.ini such that symphony_host variable point to Symphony's EC2 endpoint URL
2. Create via symphony ui access keys , My account -> Access Keys -> Create. Transfer those keys to inventory. Best way is adding them as global vaiables:
```
export AWS_ACCESS_KEY_ID='e38842a10e704e21b6cdd0069b749ad2'
export AWS_SECRET_ACCESS_KEY='10ead4734e604a26aedfc27116829d90'
```
3. Check integrity and run:
``
ansible-inventory -i /etc/ansible/ec2.py --list
``
4. In order to run playbook which use ec2 inventory(as tag-provision_playbook.yml) run:
``
ansible-playbook -i /etc/ansible/ec2.py tag-provision_playbook.yml
``

