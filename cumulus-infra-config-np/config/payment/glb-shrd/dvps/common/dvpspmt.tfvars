#################################################Provider###############################################################
ops_assume_role_arn = "arn:aws:iam::366674262526:role/dvps-shrd-svs-payment-ops"
intercom_role_arn   = "arn:aws:iam::366674262526:role/dvps-shrd-svs-payment-intercom"
stack_role_arn      = "arn:aws:iam::366674262526:role/dvps-shrd-svs-payment-product"
environment         = "dvpspmt"
product             = "glb-shrd"

#######################################################locals###########################################################
transit_gateway_id           = "tgw-05bc8796af36c0beb"
transit_gateway_spoke_rtb_id = "tgw-rtb-09649642d7a7b8e00"
transit_gateway_spoke_int_id = "tgw-rtb-0cbf4e46c8810603e"
egress_vpc_public_rtb_id     = "rtb-094d4a83372e4d650"
ingress_vpc_cidr             = "10.101.48.0/20"
ingress_vpc_public_rtb_id    = "rtb-0c0e1b02fce381f66"
ingress_vpc_id               = "vpc-00b1b1bf5e6a52266"
ops_vpc_cidr                 = "10.101.16.0/20"
ops_vpc_id                   = "vpc-09bf82d14ac826208"
dns_vpc_id                   = "vpc-09331289e3fdf384c"
hosted_zone_name             = "dp.prth.int"
hosted_zone_id               = "Z01176709OU0EN12YEQI"

####################################################data-vpc############################################################
data_vpc_cidr = "10.105.176.0/20"

####################################################application-vpc#####################################################
application_vpc_cidr = "10.105.192.0/20"
