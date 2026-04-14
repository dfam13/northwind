locals {
  name = "northwind"
}

module "network" {
  source = "../../modules/network"

  name = local.name
  vpc_cidr = "192.168.0.0/16"

  azs = ["us-east-2a", "us-east-2b"]

  public_subnets  = ["192.168.50.0/24", "192.168.70.0/24"]
  private_subnets = ["192.168.10.0/24", "192.168.30.0/24"]
}

module "rds" {
  source = "../../modules/rds"

  name            = local.name
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
  vpc_cidr        = "192.168.0.0/16"

  db_user = "adminnorthwind"
  db_pass = "securepassword123"
}

module "compute" {
  source = "../../modules/compute"

  name            = local.name
  vpc_id          = module.network.vpc_id
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets
}
