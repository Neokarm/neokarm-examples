import boto3
import sys
import random
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ---------------------------------------------------------------------------------------------------------------------

#     This script shows and example of Boto3 ELB v2 integration with Neokarm Symphony.

#     The scenario:
#          1. Create VPC
#          2. Create Internet-Gateway
#          3. Attach Internet-Gateway
#          4. Create public Subnet
#          5. Create private Subnet
#          6. Create Route-Table
#          7. Create Route
#          8. Associate Route-Table to  the public Subnet
#          9. Create instance Security-Group
#          10. Create load balancer Security-Group
#          11. Run target instances
#          12. Create load-balancer
#          13. Create target-group
#          14. Register instances to target-group
#          15. Create Listener
    
#     This example was tested on versions:
#     - Symphony version 5.5.3
#     - boto3 1.4.7

# ---------------------------------------------------------------------------------------------------------------------


def main():

    # Parameters
    CLUSTER_IP = 'API endpoint IP'
    VPC_CIDR = '172.20.0.0/16'
    PUBLIC_SUBNET_CIDR = '172.20.10.0/24'
    PRIVATE_SUBNET_CIDR = '172.20.20.0/24'
    INTERNAL_PORT = 8080
    EXTERNAL_PORT = 80
    TARGETS_COUNT = 2
    IMAGE_ID = '<IMAGE ID>'
    INSTANCE_TYPE = 't2.medium'

    

    # The following will be used to differentiate entity names in this example
    run_index = '%03x' % random.randrange(2**12)

    ##
    ### Clients
    ##

    ec2 = boto3.client(
        service_name="ec2", region_name="symphony",
        endpoint_url="https://%s/api/v2/ec2/" % CLUSTER_IP,
        verify=False
        )

    elb = boto3.client(
        service_name="elbv2", region_name="symphony",
        endpoint_url="https://%s/api/v2/aws/elb" % CLUSTER_IP,
        verify=False
        )

    ##
    ### Resources
    ##

    # Create VPC
    vpc = ec2.create_vpc(CidrBlock=VPC_CIDR)

    vpcId = vpc['Vpc']['VpcId']
    
    waiter = ec2.get_waiter('vpc_available')
    waiter.wait(
        VpcIds=[
            vpcId,
        ]
    )

    ec2.create_tags(
        Resources=[
            vpcId,
            ],
        Tags=[
            {
                'Key': 'Name',
                'Value': 'Sample VPC'
                },
            ]
        )

    print("VPC ID: %s" % vpcId)

    #Create Internet Gateway
    igw = ec2.create_internet_gateway()

    igwId = igw['InternetGateway']['InternetGatewayId']

    ec2.create_tags(
        Resources=[
            igwId,
            ],
        Tags=[
            {
                'Key': 'Name',
                'Value': 'Sample igw'
                },
            ]
        )

    print("InternetGateway ID: %s" % igwId)

    #Attach Internet Gateway to VPC
    ec2.attach_internet_gateway(
        InternetGatewayId=igwId,
        VpcId=vpcId
        )

    print("InternetGateway attached")

    #Create Subnets
    public_subnet = ec2.create_subnet(
        CidrBlock=PUBLIC_SUBNET_CIDR,
        VpcId=vpcId
        )
    
    private_subnet = ec2.create_subnet(
        CidrBlock=PRIVATE_SUBNET_CIDR,
        VpcId=vpcId
        )

    

    public_subnet_id = public_subnet['Subnet']['SubnetId']
    private_subnet_id = private_subnet['Subnet']['SubnetId']

    ec2.create_tags(
        Resources=[
            public_subnet_id,
            ],
        Tags=[
            {
                'Key': 'Name',
                'Value': 'Sample public subnet'
                },
            ]
        )
    
    ec2.create_tags(
        Resources=[
            private_subnet_id,
            ],
        Tags=[
            {
                'Key': 'Name',
                'Value': 'Sample private subnet'
                },
            ]
        )

    print("Public subnet ID: %s" % public_subnet_id)
    print("Private subnet ID: %s" % private_subnet_id)

    #Create route table in the VPC
    public_route_table = ec2.create_route_table(VpcId=vpcId)

    public_route_table_id = public_route_table['RouteTable']['RouteTableId']

    ec2.create_tags(
        Resources=[
            public_route_table_id,
            ],
        Tags=[
            {
                'Key': 'Name',
                'Value': 'Sample public RouteTable'
                },
            ]
        )

    print("Public Route Table ID: %s" % public_route_table_id)

    #Add routing rule to route table
    ec2.create_route(
        DestinationCidrBlock='0.0.0.0/0',
        GatewayId=igwId,
        RouteTableId=public_route_table_id
        )

    print("Route created")

    #Associate route table to subnet
    ec2.associate_route_table(
        RouteTableId=public_route_table_id,
        SubnetId=public_subnet_id
        )

    print("Route table %s associated to subnet %s" % (public_route_table_id, public_subnet_id))

    # Create ELB Security-Group
    elb_sg = ec2.create_security_group(
        GroupName='SAMPLE_ELB_SG_%s' % run_index,
        Description='Allow traffic for ELB',
        VpcId=vpcId
        )

    elb_sg_id = elb_sg['GroupId']

    print("Security group ID: %s" % elb_sg_id)

    ec2.authorize_security_group_ingress(
        GroupId=elb_sg_id,
        IpPermissions=[
            {
                "IpProtocol": "tcp",
                "FromPort": EXTERNAL_PORT,
                "ToPort": EXTERNAL_PORT,
                "IpRanges": [
                    {
                        "CidrIp": "0.0.0.0/0"
                        }
                    ]
                }
            ]
        )

    ec2.authorize_security_group_egress(
        GroupId=elb_sg_id,
        IpPermissions=[
            {
                "IpProtocol": "-1",
                "FromPort": 0,
                "ToPort": 0,
                "IpRanges": [
                    {
                        "CidrIp": "0.0.0.0/0"
                        }
                    ]
                }
            ]
        )

    print("Security group rules were added")

    # Create ec2 Security-Group
    ec2_sg = ec2.create_security_group(
        GroupName='SAMPLE_EC2_SG_%s' % run_index,
        Description='Allow traffic for ELB',
        VpcId=vpcId
        )

    ec2_sg_id = ec2_sg['GroupId']

    print("Security group ID: %s" % ec2_sg_id)

    ec2.authorize_security_group_ingress(
        GroupId=ec2_sg_id,
        IpPermissions=[
            {
                "IpProtocol": "tcp",
                "FromPort": INTERNAL_PORT,
                "ToPort": INTERNAL_PORT,
                "UserIdGroupPairs": [
                    {
                        'GroupId': elb_sg_id
                        }
                    ]
                }
            ]
        )

    ec2.authorize_security_group_egress(
        GroupId=ec2_sg_id,
        IpPermissions=[
            {
                "IpProtocol": "-1",
                "FromPort": 0,
                "ToPort": 0,
                "IpRanges": [
                    {
                        "CidrIp": "0.0.0.0/0"
                        }
                    ]
                }
            ]
        )

    print("Security group rules were added")

    #Run instances
    run_instances = ec2.run_instances(
        ImageId=IMAGE_ID,
        InstanceType=INSTANCE_TYPE,
        MaxCount=TARGETS_COUNT,
        MinCount=TARGETS_COUNT,
        SecurityGroupIds=[ec2_sg_id],
        SubnetId=private_subnet_id
        )

    instance_ids = list(map(lambda i: i['InstanceId'], run_instances['Instances']))

    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=instance_ids)

    ec2.create_tags(
        Resources=instance_ids,
        Tags=[
            {
                'Key': 'Name',
                'Value': 'Sample instance'
                },
            ]
        )

    print ("Created instances: " + ' '.join(p for p in instance_ids))

    load_balancer = elb.create_load_balancer(
        Name='SAMPLE_ELB_%s' % run_index,
        Subnets=[public_subnet_id],
        SecurityGroups=[elb_sg_id],
        Type='network',
        IpAddressType='ipv4'
        )

    load_balancer_id = load_balancer['LoadBalancers'][0]['LoadBalancerArn'] 

    print ('Load balancer ID: %s' % load_balancer_id)

    # create target-group
    target_group = elb.create_target_group(
        Name='SAMPLE_ELB_TG_%s' % run_index,
        Protocol='TCP',
        Port=INTERNAL_PORT,
        VpcId=vpcId
        )
    
    target_group_id = target_group['TargetGroups'][0]['TargetGroupArn']

    print ("Target group ID: %s" % target_group_id)

    # Register targets
    targets_list = [dict(Id=instance_id, Port=INTERNAL_PORT) for instance_id in instance_ids]
    elb.register_targets(
        TargetGroupArn=target_group_id,
        Targets=targets_list
        )

    print ("Targets registered")

    # create Listener
    create_listener_response = elb.create_listener(
        LoadBalancerArn=load_balancer_id,
        Protocol='TCP',
        Port=EXTERNAL_PORT,
        DefaultActions=[
            {
                'Type': 'forward',
                'TargetGroupArn': target_group_id
                }
            ]
        )

    print ("Listener ID: %s" % create_listener_response['Listeners'][0]['ListenerArn'])

if __name__ == '__main__':
    sys.exit(main())
