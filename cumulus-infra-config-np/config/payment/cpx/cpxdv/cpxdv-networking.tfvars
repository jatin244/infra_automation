#######################################################locals###########################################################
route53_resolver_rule_id = ["rslvr-rr-59fa2caf47b0451fb", "rslvr-rr-28826c90ae744458a", "rslvr-rr-6dfe09db5ced4c1ca", "rslvr-rr-93a1e335607497aab"]
vpc_flow_log_s3 = "arn:aws:s3:::nvnp-svclogs-vpcflows"
####################################################data-vpc############################################################
data_private_route_tables = {
  "us-east-1a" = {
    tagName = "private-routing-1a"
    NAT     = "us-east-1a"
  }
}
data_private_subnets = {
  "private-subnet-1a" = {
    cidr        = "10.44.1.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "shared-data"
  }
  "private-subnet-1b" = {
    cidr        = "10.44.2.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "shared-data"
  }
}

#data_msk_private_subnets = {
#  "msk-private-subnet-1a" = {
#    cidr        = "10.44.3.0/24"
#    az_name     = "us-east-1a"
#    route_table = "us-east-1a"
#    component   = "kafka"
#  }
#  "msk-private-subnet-1b" = {
#    cidr        = "10.44.4.0/24"
#    az_name     = "us-east-1b"
#    route_table = "us-east-1a"
#    component   = "kafka"
#  }
#}

####################################################application-vpc#####################################################
application_private_route_tables = {
  "us-east-1a" = {
    tagName = "private-routing-1a"
    NAT     = "us-east-1a"
  }
}
application_private_subnets = {
  "eks-shared-subnet-1a" = {
    cidr        = "10.43.4.0/22"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
  }
  "eks-shared-subnet-1b" = {
    cidr        = "10.43.8.0/22"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
  }

  "eks-ds-subnet-1a" = {
    cidr        = "10.43.1.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-ds"
  }
  "eks-ds-subnet-1b" = {
    cidr        = "10.43.12.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-ds"
  }

  "eks-mgmt-subnet-1a" = {
    cidr        = "10.43.2.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
  }
  "eks-mgmt-subnet-1b" = {
    cidr        = "10.43.13.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
  }

  "eks-open-net-subnet-1a" = {
    cidr        = "10.43.3.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-open-net"
  }
  "eks-open-net-subnet-1b" = {
    cidr        = "10.43.14.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-open-net"
  }
  "eks-open-net-subnet-2a" = {
    cidr        = "10.43.0.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-open-net"
  }
  "eks-open-net-subnet-2b" = {
    cidr        = "10.43.15.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-open-net"
  }
}
