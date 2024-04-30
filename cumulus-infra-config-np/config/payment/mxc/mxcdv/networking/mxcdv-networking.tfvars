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
    cidr        = "10.24.1.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "shared-data"
    eks_internal_elb = false #If this is true then kubernetes.io/role/internal-elb tag value is 1 and if false the value will be 0. For 1 the ALB ingress will be applied. Put this carefully
  }
  "private-subnet-1d" = {
    cidr        = "10.24.2.0/24"
    az_name     = "us-east-1d"
    route_table = "us-east-1a"
    component   = "shared-data"
    eks_internal_elb = false
  }
}
data_msk_private_subnets = {
  "msk-private-subnet-1a" = {
    cidr        = "10.24.3.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "kafka"
    eks_internal_elb = false
  }
  "msk-private-subnet-1c" = {
    cidr        = "10.24.4.0/24"
    az_name     = "us-east-1c"
    route_table = "us-east-1a"
    component   = "kafka"
    eks_internal_elb = false
  }
  "msk-private-subnet-1d" = {
    cidr        = "10.24.5.0/24"
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
  "eks-shared-subnet-1a" = {
    cidr        = "10.26.0.0/22"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }
  "eks-shared-subnet-1d" = {
    cidr        = "10.26.4.0/22"
    az_name     = "us-east-1d"
    route_table = "us-east-1a"
    component   = "eks-product-shared"
    eks_internal_elb = true
  }
  "eks-mgmt-subnet-1a" = {
    cidr        = "10.26.8.0/24"
    az_name     = "us-east-1a"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
  "eks-mgmt-subnet-1d" = {
    cidr        = "10.26.9.0/24"
    az_name     = "us-east-1d"
    route_table = "us-east-1a"
    component   = "eks-mgmt"
    eks_internal_elb = false
  }
}
