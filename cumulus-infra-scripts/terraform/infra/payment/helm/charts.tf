provider "aws" {
  alias = "ops"
  assume_role {
    role_arn = var.ops_assume_role_arn
  }
  region = var.region
}
provider "aws" {
  alias = "intercom"
  assume_role {
    role_arn = var.intercom_role_arn
  }
  region = var.region
}
provider "aws" {
  alias = "stack"
  assume_role {
    role_arn = var.stack_role_arn
  }
  region = var.region
}
data "aws_caller_identity" "stack" {
  provider = aws.stack
}
data "aws_eks_cluster_auth" "cluster" {
  count    = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) ? 1 : 0
  provider = aws.stack
  name     = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) ? data.aws_eks_cluster.eks_cluster.id : ""
}
data "aws_caller_identity" "current" {
  provider = aws.stack
}
data "aws_eks_cluster" "eks_cluster" {
  provider = aws.stack
  name     = "${var.environment}-eks-cluster"
}
data "aws_autoscaling_groups" "groups" {
  provider = aws.stack
  filter {
    name   = "tag-key"
    values = ["eks:cluster-name"]
  }
  filter {
    name   = "tag-value"
    values = ["${var.environment}-eks-cluster"]
  }
}
data "aws_vpc" "application_vpc" {
  count    = var.application_vpc_enabled == true ? 1 : 0
  provider = aws.stack
  tags = {
    Name = "${var.environment}-application" # Replace with your desired tag key-value pair
  }
}
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = join("", data.aws_eks_cluster_auth.cluster.*.token)
  }
}
provider "kubectl" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = join("", data.aws_eks_cluster_auth.cluster.*.token)
  load_config_file       = false
}
###--------------------------------------------------------Node-Terminator---------------------------------------------------------
resource "helm_release" "aws-node-termination-handler" {
  count            = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) && var.helm_release_aws_node_termination_handler_enabled ? 1 : 0
  chart            = "aws-node-termination-handler"
  create_namespace = false
  namespace        = "kube-system"
  name             = "aws-node-termination-handler"
  version          = "0.21.0"
  repository       = "https://aws.github.io/eks-charts"
  set {
    name  = "nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = "${var.environment}-eks-node-group-${var.management_node_group_identifier}"
  }
}
###------------------------------------------------------Cluster Autoscaler----------------------------------------------
#
resource "helm_release" "application" {
  count            = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) && var.helm_release_application_enabled ? 1 : 0
  name             = "application-cluster-autoscaler"
  namespace        = "kube-system"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.21.1"
  create_namespace = false
  set {
    name  = "awsRegion"
    value = var.region
  }
  set {
    name  = "autoscalingGroups[0].name"
    value = "data.aws_autoscaling_groups.groups.names"
  }
  set {
    name  = "autoscalingGroups[0].maxSize"
    value = 10
  }
  set {
    name  = "autoscalingGroups[0].minSize"
    value = 1
  }
  set {
    name  = "nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = "${var.environment}-eks-node-group-${var.management_node_group_identifier}"
  }
}
###--------------------------------------------------Kube-state Metrics-------------------------------------------------------------------
resource "helm_release" "kube-state-metrics" {
  count            = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) && var.helm_release_kube_state_metrics_enabled ? 1 : 0
  chart            = "kube-state-metrics"
  create_namespace = false
  namespace        = "kube-system"
  name             = "kube-state-metrics"
  version          = "4.13.0"
  repository       = "https://prometheus-community.github.io/helm-charts"
  set {
    name  = "nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = "${var.environment}-eks-node-group-${var.management_node_group_identifier}"
  }
}
###-------------------------------------------------- Metrics-------------------------------------------------------------------
resource "helm_release" "metrics-server" {
  count            = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) && var.helm_release_metrics_server_enabled ? 1 : 0
  chart            = "metrics-server"
  create_namespace = false
  namespace        = "kube-system"
  name             = "metrics-server"
  version          = "3.8.3"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  set {
    name  = "nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = "${var.environment}-eks-node-group-${var.management_node_group_identifier}"
  }
}
###--------------------------------------------------------alb-ingress---------------------------------------------------------
data "kubectl_file_documents" "docs" {
  count   = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) ? 1 : 0
  content = file("./crds.yaml")
}
resource "kubectl_manifest" "test" {
  for_each  = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) ? data.kubectl_file_documents.docs.0.manifests : {}
  yaml_body = each.value
}
resource "helm_release" "albingress" {
  count           = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) && var.helm_release_albingress_enabled ? 1 : 0
  name            = "aws-load-balancer-controller"
  chart           = "aws-load-balancer-controller"
  repository      = "https://aws.github.io/eks-charts"
  namespace       = "kube-system"
  cleanup_on_fail = true
  force_update    = true
  version         = "1.5.4"
  set {
    name  = "image.tag"
    value = "v2.5.1"
  }
  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.eks_cluster.id
  }
  set {
    name  = "vpcId"
    value = var.application_vpc_enabled == false ? var.application_vpc_id : join("", data.aws_vpc.application_vpc.*.id)
  }
  set {
    name  = "region"
    value = "us-east-1"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.create"
    value = true
  }
  set {
    name  = "replicaCount"
    value = "1"
  }
  set {
    name = "enableServiceMutatorWebhook"
    value = "false"
  }
  set {
    name  = "nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = "${var.environment}-eks-node-group-${var.management_node_group_identifier}"
  }
  depends_on = [kubectl_manifest.test]
}
