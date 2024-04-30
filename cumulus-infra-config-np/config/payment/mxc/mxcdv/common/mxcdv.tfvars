##################State File Maintenance ########################
# S3 Bucket in glb-cbdp account - iaas-cibuilder-tf-state
# State File Path - terraform/mxcdv/
################################################Provider###############################################################
ops_assume_role_arn = "arn:aws:iam::304575748023:role/MXC-CIBuilder-Ops-Engg"
intercom_role_arn   = "arn:aws:iam::762861681156:role/MXC-CIBuilder-Intercom-Engg"
stack_role_arn      = "arn:aws:iam::654274741818:role/MXC-CIBuilder-Product-Engg"
environment         = "mxcdv"
product             = "mxc"

#######################################################locals###########################################################
transit_gateway_id           = "tgw-0ae34d2891f6f7fa6"
transit_gateway_spoke_rtb_id = "tgw-rtb-046ed68471dbcda81"
transit_gateway_spoke_int_id = "tgw-rtb-04525ebd8e7473a31"
egress_vpc_public_rtb_id     = "rtb-00c2387634e6cd021"
ingress_vpc_cidr             = "172.25.128.0/20"
ingress_vpc_public_rtb_id    = "rtb-0e56bda3cf62ea1ca"
ingress_vpc_id               = "vpc-06aa86de510d0509c"
ops_vpc_cidr                 = "172.25.80.0/20"
ops_vpc_id                   = "vpc-0d94d18ef5e46a956"
dns_vpc_id                   = "vpc-0d961bd68b1276be6"
hosted_zone_name             = "np.prth.local" 
hosted_zone_id               = "Z0564577CIT7N7I4E8PL"

####################################################data-vpc############################################################
data_vpc_cidr = "10.24.0.0/20"

####################################################application-vpc#####################################################
application_vpc_cidr = "10.26.0.0/20"
