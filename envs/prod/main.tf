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
  db_username               = var.db_username
  db_password               = var.db_password
  multi_az                  = var.multi_az
}


module "github_oidc" {
  source      = "../../modules/github-oidc"
  github_org  = var.github_org
  github_repo = var.github_repo
}
