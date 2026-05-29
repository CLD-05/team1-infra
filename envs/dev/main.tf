# main.tf

module "vpc" {
  source            = "../../modules/vpc"
  project           = var.project
  cluster_name      = var.cluster_name
  vpc_cidr          = var.vpc_cidr
  azs               = var.azs
  public_cidrs      = var.public_cidrs
  private_cidrs     = var.private_cidrs
  isolated_cidrs    = var.isolated_cidrs
  enable_nat_per_az = var.enable_nat_per_az
}

module "bastion" {
  source           = "../../modules/bastion"
  project          = var.project
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  instance_type    = "t3.micro"
  use_ssm          = var.use_ssm
  key_name         = var.key_name
  my_ip            = var.my_ip
}
module "eks" {
  source                    = "../../modules/eks"
  cluster_name              = var.cluster_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  bastion_security_group_id = module.bastion.security_group_id
  bastion_role_arn          = module.bastion.role_arn
  node_instance_type        = var.node_instance_type
  node_min                  = var.node_min
  node_max                  = var.node_max
  node_desired              = var.node_desired
}

module "ecr" {
  source       = "../../modules/ecr"
  project      = var.project
  repositories = var.repositories
}

module "rds" {
  source                    = "../../modules/rds"
  project                   = var.project
  vpc_id                    = module.vpc.vpc_id
  isolated_subnet_ids       = module.vpc.isolated_subnet_ids
  node_security_group_id    = module.eks.node_security_group_id
  bastion_security_group_id = module.bastion.security_group_id
  db_username               = data.aws_ssm_parameter.db_username.value
  db_password               = data.aws_ssm_parameter.db_password.value
  multi_az                  = var.multi_az
}

data "aws_ssm_parameter" "db_username" {
  name = "/team1/eks-dev/db-username"
}

data "aws_ssm_parameter" "db_password" {
  name            = "/team1/eks-dev/db-password"
  with_decryption = true
}

module "github_oidc" {
  source      = "../../modules/github-oidc"
  project     = var.project
  github_org  = var.github_org
  github_repo = var.github_repo
}

# # SSM에서 읽기
# data "aws_ssm_parameter" "slack_webhook" {
#   name            = "/team1/dev/monitoring/slack-webhook"
#   with_decryption = true
# }

# module "cloudfront" {
#   source          = "../../modules/cloudfront"
#   env             = var.environment
#   aws_account_id  = var.aws_account_id
#   domain_name     = var.domain_name
#   route53_zone_id = var.route53_zone_id
#   alb_dns_name    = var.alb_dns_name
# }

# module "monitoring" {
#   source              = "../../modules/monitoring"
#   env                 = var.environment
#   eks_cluster_name    = var.cluster_name
#   rds_instance_id     = module.rds.primary_instance_id
#   rds_max_connections = 1000
#   slack_webhook_url   = data.aws_ssm_parameter.slack_webhook.value
# }
