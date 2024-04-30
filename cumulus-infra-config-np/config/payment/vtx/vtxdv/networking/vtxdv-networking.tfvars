#######################################################locals###########################################################
route53_resolver_rule_id = ["rslvr-rr-59fa2caf47b0451fb", "rslvr-rr-28826c90ae744458a", "rslvr-rr-6dfe09db5ced4c1ca", "rslvr-rr-93a1e335607497aab"]
vpc_flow_log_s3 = "arn:aws:s3:::nvnp-svclogs-vpcflows"
####################################################data-vpc############################################################
data_private_route_tables = {
  "us-east-1c" = {
    tagName = "private-routing-data"
    NAT     = "us-east-1c"
  }
}
data_private_subnets = {
  "private-subnet-1c" = {
    cidr        = "10.15.32.0/24"
    az_name     = "us-east-1c"
    route_table = "us-east-1c"
    component   = "shared-data"
    eks_internal_elb = false #If this is true then kubernetes.io/role/internal-elb tag value is 1 and if false the value will be 0. For 1 the ALB ingress will be applied. Put this carefully
  }
  "private-subnet-1d" = {
    cidr        = "10.15.33.0/24"
    az_name     = "us-east-1d"
    route_table = "us-east-1c"
    component   = "shared-data"
    eks_internal_elb = false #If this is true then kubernetes.io/role/internal-elb tag value is 1 and if false the value will be 0. For 1 the ALB ingress will be applied. Put this carefully
  }
}
data_msk_private_subnets = {
  "msk-private-subnet-1c" = {
    cidr        = "10.15.34.0/24"
    az_name     = "us-east-1c"
    route_table = "us-east-1c"
    component   = "kafka"
    eks_internal_elb = false
  }
  "msk-private-subnet-1d" = {
    cidr        = "10.15.35.0/24"
    az_name     = "us-east-1d"
    route_table = "us-east-1c"
    component   = "kafka"
    eks_internal_elb = false
  }
    "msk-private-subnet-1b" = {
    cidr        = "10.15.36.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1c"
    component   = "kafka"
    eks_internal_elb = false
  }
}

####################################################application-vpc#####################################################
application_private_route_tables = {
  "us-east-1c" = {
    tagName = "private-routing-app"
    NAT     = "us-east-1c"
  }
}
application_private_subnets = {
  "private-subnet-1c" = {
    cidr        = "10.15.16.0/22"
    az_name     = "us-east-1c"
    route_table = "us-east-1c"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }
  "private-subnet-1d" = {
    cidr        = "10.15.20.0/22"
    az_name     = "us-east-1d"
    route_table = "us-east-1c"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }
  
  "eks-mgmt-subnet-1c" = {
    cidr        = "10.15.24.0/24"
    az_name     = "us-east-1c"
    route_table = "us-east-1c"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
  "eks-mgmt-subnet-1d" = {
    cidr        = "10.15.25.0/24"
    az_name     = "us-east-1d"
    route_table = "us-east-1c"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
}
