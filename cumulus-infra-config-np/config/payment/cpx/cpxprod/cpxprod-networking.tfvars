#######################################################locals###########################################################
route53_resolver_rule_id = ["rslvr-rr-59fa2caf47b0451fb", "rslvr-rr-28826c90ae744458a", "rslvr-rr-6dfe09db5ced4c1ca", "rslvr-rr-93a1e335607497aab"]

####################################################data-vpc############################################################
data_private_route_tables = {
  "us-east-1b" = {
    tagName = "private-routing-1b"
    NAT     = "us-east-1b"
  }
}
data_private_subnets = {
  "private-subnet-1b" = {
    cidr        = "10.33.1.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1b"
    component   = "shared-data"
  }
  "private-subnet-1c" = {
    cidr        = "10.33.2.0/24"
    az_name     = "us-east-1c"
    route_table = "us-east-1b"
    component   = "shared-data"
  }
}

data_msk_private_subnets = {
  "msk-private-subnet-1b" = {
    cidr        = "10.33.3.0/24"
    az_name     = "us-east-1b"
    route_table = "us-east-1b"
    component   = "kafka"
  }
  "msk-private-subnet-1c" = {
    cidr        = "10.33.4.0/24"
    az_name     = "us-east-1c"
    route_table = "us-east-1b"
    component   = "kafka"
  }
  "msk-private-subnet-1d" = {
    cidr        = "10.33.5.0/24"
    az_name     = "us-east-1d"
    route_table = "us-east-1b"
    component   = "kafka"
  }
}

####################################################application-vpc#####################################################
application_private_route_tables = {
  "us-east-1b" = {
    tagName = "private-routing-1b"
    NAT     = "us-east-1b"
  }
}
application_private_subnets = {
  "private-subnet-1b" = {
    cidr        = "10.32.4.0/22"
    az_name     = "us-east-1b"
    route_table = "us-east-1b"
    component   = "eks"
  }
  "private-subnet-1c" = {
    cidr        = "10.32.8.0/22"
    az_name     = "us-east-1c"
    route_table = "us-east-1b"
    component   = "eks"
   
  }
}
