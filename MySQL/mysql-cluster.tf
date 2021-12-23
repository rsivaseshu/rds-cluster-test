locals {
  name   = "example-${replace(basename(path.cwd), "_", "-")}"
  region = "eu-west-1"
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

################################################################################
# Supporting Resources
################################################################################

resource "random_password" "master" {
  length = 10
}

################################################################################
# RDS Aurora Module
################################################################################

module "aurora" {
  source = "git@github.com:rsivaseshu/tf-rds-cluster.git?ref=main"

  name           = local.name
  engine         = "aurora-mysql"
  engine_version = "5.7.12"
  instances = {
    1 = {
      instance_class      = "db.r5.large"
      publicly_accessible = true
    }
    2 = {
      identifier     = "mysql-static-1"
      instance_class = "db.r5.2xlarge"
    }
    3 = {
      identifier     = "mysql-excluded-1"
      instance_class = "db.r5.xlarge"
      promotion_tier = 15
    }
  }

  vpc_id                 = "vpc-4ee66134"
  subnets                = ["subnet-dbecd791", "subnet-113f802f", "subnet-c9b8cc95", "subnet-67e5c868", "subnet-96442ff1"]
  create_db_subnet_group = true
  create_security_group  = true
  allowed_cidr_blocks    = ["0.0.0.0/0"]

  master_password        = random_password.master.result
  create_random_password = false

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.example.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.example.id
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = local.tags
}

resource "aws_db_parameter_group" "example" {
  name        = "${local.name}-aurora-db-57-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.name}-aurora-db-57-parameter-group"
  tags        = local.tags
}

resource "aws_rds_cluster_parameter_group" "example" {
  name        = "${local.name}-aurora-57-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.name}-aurora-57-cluster-parameter-group"
  tags        = local.tags
}
