#######################################################locals###########################################################
route53_resolver_rule_id = ["rslvr-rr-59fa2caf47b0451fb", "rslvr-rr-28826c90ae744458a", "rslvr-rr-6dfe09db5ced4c1ca", "rslvr-rr-93a1e335607497aab"]
vpc_flow_log_s3 = "arn:aws:s3:::nvnp-svclogs-vpcflows"
####################################################data-vpc############################################################
data_private_route_tables = {
  "us-east-1a" = {
    tagName = "private-routing-data"
    NAT     = "us-east-1a"
  }
}
data_private_subnets = {
  "private-subnet-1a" = {
    cidr        = "10.106.1.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "shared-data"
    eks_internal_elb = false #If this is true then kubernetes.io/role/internal-elb tag value is 1 and if false the value will be 0. For 1 the ALB ingress will be applied. Put this carefully
  }
  "private-subnet-1b" = {
    cidr        = "10.106.2.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "shared-data"
    eks_internal_elb = false #If this is true then kubernetes.io/role/internal-elb tag value is 1 and if false the value will be 0. For 1 the ALB ingress will be applied. Put this carefully
  }
}
data_msk_private_subnets = {
  "msk-private-subnet-1a" = {
    cidr        = "10.106.3.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "kafka"
    eks_internal_elb = false
  }
  "msk-private-subnet-1b" = {
    cidr        = "10.106.4.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "kafka"
    eks_internal_elb = false
  }
    "msk-private-subnet-1d" = {
    cidr        = "10.106.5.0/24"
    az_name     = "us-east-1d"
    route_table = "us-east-1a"
    component   = "kafka"
    eks_internal_elb = false
  }
}

####################################################application-vpc#####################################################
application_private_route_tables = {
  "us-east-1a" = {
    tagName = "private-routing-app"
    NAT     = "us-east-1a"
  }
}
application_private_subnets = {
  "private-subnet-1a" = {
    cidr        = "10.106.24.0/22"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }
  "private-subnet-1b" = {
    cidr        = "10.106.28.0/22"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }
  
  "eks-mgmt-subnet-1a" = {
    cidr        = "10.106.32.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
  "eks-mgmt-subnet-1a" = {
    cidr        = "10.106.33.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
}
