#######################################################locals###########################################################
route53_resolver_rule_id = ["rslvr-rr-6923854b6b3f4d95b", "rslvr-rr-19ec8677cb4748478"]
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
    cidr        = "10.105.177.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "shared-data"
    eks_internal_elb = false
  }
  "private-subnet-1b" = {
    cidr        = "10.105.179.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "shared-data"
    eks_internal_elb = false
  }
}

data_msk_private_subnets = {
  "msk-private-subnet-1a" = {
    cidr        = "10.105.178.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "kafka"
    eks_internal_elb = false
  }
  "msk-private-subnet-1b" = {
    cidr        = "10.105.180.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "kafka"
    eks_internal_elb = false
  }
}

####################################################application-vpc#####################################################
application_private_route_tables = {
  "us-east-1a" = {
    tagName = "private-routing-1a"
    NAT     = "us-east-1a"
  }
}
application_private_subnets = {
  "eks-shared-subnet-1a" = {
    cidr        = "10.105.196.0/22"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }
  "eks-shared-subnet-1b" = {
    cidr        = "10.105.200.0/22"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }

  "eks-ds-subnet-1a" = {
    cidr        = "10.105.193.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-ds"
    eks_internal_elb = false
  }
  "eks-ds-subnet-1b" = {
    cidr        = "10.105.204.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-ds"
    eks_internal_elb = false
  }

  "eks-mgmt-subnet-1a" = {
    cidr        = "10.105.194.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
  "eks-mgmt-subnet-1b" = {
    cidr        = "10.105.205.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
}
