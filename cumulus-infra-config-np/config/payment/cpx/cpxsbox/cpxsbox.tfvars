##################State File Maintenance ########################
# S3 Bucket in Global Ops Prod - payment-infra-teraform-state
# State File Path - terraform/pmt/cpx/cpxsbox
#################################################Provider###############################################################
ops_assume_role_arn = "arn:aws:iam::847632215575:role/CPX-CIBuilder-Ops-Prod"
intercom_role_arn   = "arn:aws:iam::762861681156:role/CPX-CIBuilder-Intercom-Prod"
stack_role_arn      = "arn:aws:iam::015987925177:role/CPX-CIBuilder-Product-sbox"
environment         = "cpxsbox"
product             = "cpx"

#######################################################locals###########################################################
transit_gateway_id           = "tgw-01fa4f5c35fde259a"
transit_gateway_spoke_rtb_id = "tgw-rtb-098fb92091509884f"
transit_gateway_spoke_int_id = "tgw-rtb-011af727a55ef3e99"
egress_vpc_public_rtb_id     = "rtb-000d990229b4fc918"
ingress_vpc_cidr             = "172.20.192.0/20"
ingress_vpc_public_rtb_id    = "rtb-0f598da098c6c0f9d"
ingress_vpc_id               = "vpc-02a6330a96d8eda80"
ops_vpc_cidr                 = "172.20.96.0/20"
ops_vpc_id                   = "vpc-083eb7dbf43a53e29"
dns_vpc_id                   = "vpc-0d961bd68b1276be6"
hosted_zone_name             = "pr.prth.local"
hosted_zone_id               = "Z064902716FMNDDMQFCGA"

####################################################data-vpc############################################################
data_vpc_cidr = "10.49.0.0/20"

####################################################application-vpc#####################################################
application_vpc_cidr = "10.48.0.0/20"
