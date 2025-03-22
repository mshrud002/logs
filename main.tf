 # AWS provider
 provider "aws" {
   region = "us-east-1"
}



# data "aws_availability_zones" "available" {}

# variable "eks_sg_id" {
#   description = "EKS Security Group ID"
#   type        = string
#   default     = "sg-0f50e6ad89c1cbdf3"
# }

# locals {
#   cluster_name = "terraform-2-eks-${random_string.suffix.result}"
# }

# resource "random_string" "suffix" {
#   length  = 8
#   special = false
# }

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "3.19.0"

#   name = "terraform-vpc"

#   cidr = "10.0.0.0/16"
#   azs  = slice(data.aws_availability_zones.available.names, 0, 3)

#   private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#   public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

#   enable_nat_gateway   = true
#   single_nat_gateway   = true
#   enable_dns_hostnames = true

#   public_subnet_tags = {
#     "kubernetes.io/cluster/${local.cluster_name}" = "shared"
#     "kubernetes.io/role/elb"                      = 1
#   }

#   private_subnet_tags = {
#     "kubernetes.io/cluster/${local.cluster_name}" = "shared"
#     "kubernetes.io/role/internal-elb"             = 1
#   }
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "19.5.1"

#   cluster_name    = local.cluster_name
#   cluster_version = "1.31"
#   ##

#   vpc_id                         = module.vpc.vpc_id
#   subnet_ids                     = module.vpc.private_subnets
#   cluster_endpoint_public_access = true

#   eks_managed_node_group_defaults = {
#     ami_type = "AL2_x86_64"

#   }

#   eks_managed_node_groups = {
#     one = {
#       name = "node-group-1"

#       instance_types = ["t3.small"]

#       min_size     = 1
#       max_size     = 3
#       desired_size = 2
#     }

#     two = {
#       name = "node-group-2"

#       instance_types = ["t3.small"]

#       min_size     = 1
#       max_size     = 2
#       desired_size = 1
#     }
#   }
# }

# # Accessing the instances of the node group
# #output "node_group_instances" {
# #  value = module.eks.node_groups["node-group-1"].instances
# #}


# # https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/
# data "aws_iam_policy" "ebs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# module "irsa-ebs-csi" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "4.7.0"

#   create_role                   = true
#   role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
#   provider_url                  = module.eks.oidc_provider
#   role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# }

# resource "aws_eks_addon" "ebs-csi" {
#   cluster_name             = module.eks.cluster_name
#   addon_name               = "aws-ebs-csi-driver"
#   addon_version            = "v1.37.0-eksbuild.1"
#   service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
#   tags = {
#     "eks_addon" = "ebs-csi"
#     "terraform" = "true"
#   }
# }


# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.main.token
# }


# provider "helm" {
#   kubernetes {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#     token                  = data.aws_eks_cluster_auth.main.token
#   }
# }


# resource "helm_release" "rancher" {
#   name       = "rancher"
#   namespace  = "cattle-system"
#   repository = "https://releases.rancher.com/server-charts/stable"
#   chart      = "rancher"
#   version    = "2.10.3"
#   create_namespace = true

#   set {
#     name  = "hostname"
#     value = "rancher.rancher-kubestronaut.com"
#   }

#   set {
#     name  = "ingress.tls.source"
#     value = "secret"
#   }

#   set {
#     name  = "replicas"
#     value = "3"
#   }

#     set {
#     name  = "ingress.enabled"
#     value = "true"
#   }

#   set {
#     name  = "ingress.ingressClassName"
#     value = "alb" # assuming you're using AWS ALB ingress controller
#   }

#   set {
#     name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
#     value = "alb"
#   }

#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
#     value = "internet-facing"
#   }

#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
#     value = "ip"
#   }

#   set {
#     name  = "ingress.tls.enabled"
#     value = "false" # or true if using ACM certs
#   }

#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports-80"
#     value = "80"
#   }

#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports-443"
#     value = "443"
#   }
# }

# # EKS cluster authentication (required for Helm)
# data "aws_eks_cluster_auth" "main" {
#   name = module.eks.cluster_name
# }


# ###################### Add ALB Listener security group ###########################################

# resource "aws_security_group" "rancher_lb_sg" {
#   name   = "rancher-lb-sg"
#   vpc_id = module.vpc.vpc_id

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# ###################### ALB tO EXPOSE RANCHER ##############################################

# resource "aws_lb" "rancher_lb" {
#   name               = "rancher-lb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [
#     var.eks_sg_id,
#     aws_security_group.rancher_lb_sg.id
#     ]
#   subnets            = module.vpc.public_subnets
#   enable_deletion_protection = false
# }
# ####################### EKS Loadbalancer For Rancher ######################################
# resource "aws_lb_target_group" "rancher_target_group" {
#   name     = "rancher-target-group"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = module.vpc.vpc_id
#   #target_type = "IP"
#   target_type = "instance" 

#   health_check {
#     path                = "/healthz"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 2
#   }
# }

# ###################################### Forward Requests to Rancher ######################
# resource "aws_lb_listener" "rancher_listener" {
#   load_balancer_arn = aws_lb.rancher_lb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.rancher_target_group.arn
#   }
# }


# ################################### Register odes as a target ##########################

# # Extract the first Auto Scaling Group name from the EKS module output
# data "aws_autoscaling_group" "eks_asg" {
#   name = module.eks.eks_managed_node_groups_autoscaling_group_names[0]
# }

# # Use aws_instance data source to filter instances in the ASG
# data "aws_instances" "eks_worker_nodes" {
#   filter {
#     name   = "tag:aws:autoscaling:groupName"
#     values = [data.aws_autoscaling_group.eks_asg.name]
#   }
# }

# output "eks_worker_node_ids" {
#   value = data.aws_instances.eks_worker_nodes.ids
# }

# # Attach instances to the load balancer target group
# resource "aws_lb_target_group_attachment" "rancher_targets" {
#   count            = length(data.aws_instances.eks_worker_nodes.ids)
#   target_group_arn = aws_lb_target_group.rancher_target_group.arn
#   target_id        = element(data.aws_instances.eks_worker_nodes.ids, count.index)
#   port             = 80
# }
# ############################### Output url #######################################

# output "rancher_lb_dns_name" {
#   value = aws_lb.rancher_lb.dns_name
# }


# ############################## ALB Controller @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# module "alb_ingress_controller_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "4.7.0"

#   create_role                   = true
#   role_name                     = "aws-load-balancer-controller-${module.eks.cluster_name}"
#   provider_url                  = module.eks.oidc_provider
#   role_policy_arns              = ["arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
# }

# resource "helm_release" "aws_load_balancer_controller" {
#   name       = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   version    = "1.8.1"

#   set {
#     name  = "clusterName"
#     value = module.eks.cluster_name
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }

#   set {
#     name  = "region"
#     value = "us-east-1" # Change based on your region
#   }

#   set {
#     name  = "vpcId"
#     value = module.vpc.vpc_id
#   }

#   depends_on = [module.alb_ingress_controller_irsa]
# }

# resource "kubernetes_service_account" "aws_lb_controller_sa" {
#   metadata {
#     name      = "aws-load-balancer-controller"
#     namespace = "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = module.alb_ingress_controller_irsa.iam_role_arn
#     }
#   }
# }




# # # https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/
# # data "aws_iam_policy" "ebs_csi_policy" {
# #   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# # }

# # module "irsa-ebs-csi" {
# #   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
# #   version = "4.7.0"

# #   create_role                   = true
# #   role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
# #   provider_url                  = module.eks.oidc_provider
# #   role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
# #   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# # }

# # resource "aws_eks_addon" "ebs-csi" {
# #   cluster_name             = module.eks.cluster_name
# #   addon_name               = "aws-ebs-csi-driver"
# #   addon_version            = "v1.37.0-eksbuild.1"
# #   service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
# #   tags = {
# #     "eks_addon" = "ebs-csi"
# #     "terraform" = "true"
# #   }
# # }


# # vault policy write devwebapp - <<EOF
# # path "database/config/m" {
# #   capabilities = ["read"]
# # }
# # EOF

