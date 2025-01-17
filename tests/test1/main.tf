provider "aws" {
  version = "~> 1.2"
  region  = "us-west-2"
}

provider "random" {
  version = "~> 1.0"
}

data "aws_region" "current_region" {}

resource "random_string" "password" {
  length      = 16
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "random_string" "sqs_rstring" {
  length  = 18
  upper   = false
  special = false
}

resource "random_string" "name_rstring" {
  length  = 8
  special = false
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=master"

  vpc_name = "${random_string.name_rstring.result}-ec2-asg-basenetwork-test1"
}

resource "aws_sqs_queue" "ec2-asg-test_sqs" {
  name = "${random_string.sqs_rstring.result}-my-example-queue"
}

module "sns_sqs" {
  source     = "git@github.com:rackspace-infrastructure-automation/aws-terraform-sns?ref=master"
  topic_name = "${random_string.sqs_rstring.result}-ec2-asg-test-topic"

  create_subscription_1 = true
  protocol_1            = "sqs"
  endpoint_1            = "${aws_sqs_queue.ec2-asg-test_sqs.arn}"
}

module "ec2_asg_centos7_with_codedeploy_test" {
  source    = "../../module"
  ec2_os    = "centos7"
  asg_count = "2"

  #  load_balancer_names                    = ["${aws_elb.my_elb.name}"]
  cw_low_operator = "LessThanThreshold"

  instance_role_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole",
    "arn:aws:iam::aws:policy/CloudWatchActionsEC2Access",
  ]

  instance_role_managed_policy_arn_count = "2"
  environment                            = "Development"
  ssm_association_refresh_rate           = "rate(1 day)"
  cw_scaling_metric                      = "CPUUtilization"
  enable_ebs_optimization                = "False"
  scaling_min                            = "1"
  cloudwatch_log_retention               = "30"
  secondary_ebs_volume_size              = "60"
  rackspace_managed                      = true
  cw_high_period                         = "60"
  enable_scaling_notification            = true
  subnets                                = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  secondary_ebs_volume_iops              = "0"
  ec2_scale_down_adjustment              = "1"
  cw_low_period                          = "300"
  key_pair                               = "CircleCI"
  tenancy                                = "default"
  backup_tag_value                       = "False"
  ec2_scale_down_cool_down               = "60"
  instance_type                          = "t2.micro"

  # If ALB target groups are being used, one can specify ARNs like the commented line below.
  #target_group_arns                      = ["${aws_lb_target_group.my_tg.arn}"]
  secondary_ebs_volume_type = "gp2"

  ec2_scale_up_adjustment    = "1"
  cw_high_threshold          = "60"
  scaling_notification_topic = "${module.sns_sqs.topic_arn}"
  cw_low_threshold           = "30"
  resource_name              = "${random_string.name_rstring.result}-ec2_asg_centos7_with_codedeploy"
  ec2_scale_up_cool_down     = "60"
  ssm_patching_group         = "Group1Patching"
  health_check_grace_period  = "300"
  security_group_list        = ["${module.vpc.default_sg}"]
  perform_ssm_inventory_tag  = "True"
  terminated_instances       = "30"
  health_check_type          = "EC2"
  cw_low_evaluations         = "3"
  cw_high_evaluations        = "3"
  primary_ebs_volume_iops    = "0"
  detailed_monitoring        = "True"
  primary_ebs_volume_type    = "gp2"
  primary_ebs_volume_size    = "60"
  scaling_max                = "2"
  cw_high_operator           = "GreaterThanThreshold"
  install_codedeploy_agent   = "False"

  additional_ssm_bootstrap_list = [
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-Install_Package",
          "documentParameters": {
            "Packages": "bind bindutils"
          },
          "documentType": "SSMDocument"
        },
        "name": "InstallBindAndTools",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "AWS-RunShellScript",
          "documentParameters": {
            "commands": ["touch /tmp/myfile"]
          },
          "documentType": "SSMDocument"
        },
        "name": "CreateFile",
        "timeoutSeconds": 300
      }
EOF
    },
  ]

  additional_ssm_bootstrap_step_count = "2"

  additional_tags = [
    {
      key                 = "MyTag1"
      value               = "Myvalue1"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag2"
      value               = "Myvalue2"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag3"
      value               = "Myvalue3"
      propagate_at_launch = true
    },
  ]

  encrypt_secondary_ebs_volume  = "False"
  asg_wait_for_capacity_timeout = "10m"
}

module "ec2_asg_centos7_no_codedeploy_test" {
  source    = "../../module"
  ec2_os    = "centos7"
  asg_count = "2"

  #  load_balancer_names                    = ["${aws_elb.my_elb.name}"]
  cw_low_operator = "LessThanThreshold"

  instance_role_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole",
    "arn:aws:iam::aws:policy/CloudWatchActionsEC2Access",
  ]

  instance_role_managed_policy_arn_count = "2"
  environment                            = "Development"
  ssm_association_refresh_rate           = "rate(1 day)"
  cw_scaling_metric                      = "CPUUtilization"
  enable_ebs_optimization                = "False"
  scaling_min                            = "1"
  cloudwatch_log_retention               = "30"
  secondary_ebs_volume_size              = "60"
  rackspace_managed                      = true
  cw_high_period                         = "60"
  enable_scaling_notification            = true
  subnets                                = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  secondary_ebs_volume_iops              = "0"
  ec2_scale_down_adjustment              = "1"
  cw_low_period                          = "300"
  key_pair                               = "CircleCI"
  tenancy                                = "default"
  backup_tag_value                       = "False"
  ec2_scale_down_cool_down               = "60"
  instance_type                          = "t2.micro"

  # If ALB target groups are being used, one can specify ARNs like the commented line below.
  #target_group_arns                      = ["${aws_lb_target_group.my_tg.arn}"]
  secondary_ebs_volume_type = "gp2"

  ec2_scale_up_adjustment    = "1"
  cw_high_threshold          = "60"
  scaling_notification_topic = "${module.sns_sqs.topic_arn}"
  cw_low_threshold           = "30"
  resource_name              = "${random_string.name_rstring.result}-ec2_asg_centos7_no_codedeploy"
  ec2_scale_up_cool_down     = "60"
  ssm_patching_group         = "Group1Patching"
  health_check_grace_period  = "300"
  security_group_list        = ["${module.vpc.default_sg}"]
  perform_ssm_inventory_tag  = "True"
  terminated_instances       = "30"
  health_check_type          = "EC2"
  cw_low_evaluations         = "3"
  cw_high_evaluations        = "3"
  primary_ebs_volume_iops    = "0"
  detailed_monitoring        = "True"
  primary_ebs_volume_type    = "gp2"
  primary_ebs_volume_size    = "60"
  scaling_max                = "2"
  cw_high_operator           = "GreaterThanThreshold"
  install_codedeploy_agent   = "False"

  additional_ssm_bootstrap_list = [
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-Install_Package",
          "documentParameters": {
            "Packages": "bind bindutils"
          },
          "documentType": "SSMDocument"
        },
        "name": "InstallBindAndTools",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "AWS-RunShellScript",
          "documentParameters": {
            "commands": ["touch /tmp/myfile"]
          },
          "documentType": "SSMDocument"
        },
        "name": "CreateFile",
        "timeoutSeconds": 300
      }
EOF
    },
  ]

  additional_ssm_bootstrap_step_count = "2"

  additional_tags = [
    {
      key                 = "MyTag1"
      value               = "Myvalue1"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag2"
      value               = "Myvalue2"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag3"
      value               = "Myvalue3"
      propagate_at_launch = true
    },
  ]

  encrypt_secondary_ebs_volume  = "False"
  asg_wait_for_capacity_timeout = "10m"
}

module "ec2_asg_windows_with_codedeploy_test" {
  source    = "../../module"
  ec2_os    = "windows2016"
  asg_count = "2"

  #  load_balancer_names                    = ["${aws_elb.my_elb.name}"]
  cw_low_operator = "LessThanThreshold"

  instance_role_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole",
    "arn:aws:iam::aws:policy/CloudWatchActionsEC2Access",
  ]

  instance_role_managed_policy_arn_count = "2"
  environment                            = "Development"
  ssm_association_refresh_rate           = "rate(1 day)"
  cw_scaling_metric                      = "CPUUtilization"
  enable_ebs_optimization                = "False"
  scaling_min                            = "1"
  cloudwatch_log_retention               = "30"
  secondary_ebs_volume_size              = "60"
  rackspace_managed                      = true
  cw_high_period                         = "60"
  enable_scaling_notification            = true
  subnets                                = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  secondary_ebs_volume_iops              = "0"
  ec2_scale_down_adjustment              = "1"
  cw_low_period                          = "300"
  key_pair                               = "CircleCI"
  tenancy                                = "default"
  backup_tag_value                       = "False"
  ec2_scale_down_cool_down               = "60"
  instance_type                          = "t2.micro"

  # If ALB target groups are being used, one can specify ARNs like the commented line below.
  #target_group_arns                      = ["${aws_lb_target_group.my_tg.arn}"]
  secondary_ebs_volume_type = "gp2"

  ec2_scale_up_adjustment    = "1"
  cw_high_threshold          = "60"
  scaling_notification_topic = "${module.sns_sqs.topic_arn}"
  cw_low_threshold           = "30"
  resource_name              = "${random_string.name_rstring.result}-ec2_asg_windows_with_codedeploy"
  ec2_scale_up_cool_down     = "60"
  ssm_patching_group         = "Group1Patching"
  health_check_grace_period  = "300"
  security_group_list        = ["${module.vpc.default_sg}"]
  perform_ssm_inventory_tag  = "True"
  terminated_instances       = "30"
  health_check_type          = "EC2"
  cw_low_evaluations         = "3"
  cw_high_evaluations        = "3"
  primary_ebs_volume_iops    = "0"
  detailed_monitoring        = "True"
  primary_ebs_volume_type    = "gp2"
  primary_ebs_volume_size    = "60"
  scaling_max                = "2"
  cw_high_operator           = "GreaterThanThreshold"
  install_codedeploy_agent   = "False"

  additional_ssm_bootstrap_list = [
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-Install_Datadog",
          "documentType": "SSMDocument"
        },
        "name": "InstallDataDog",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "AWS-RunPowerShellScript",
          "documentParameters": {
            "commands": ["echo $null >> C:\testfile"]
          },
          "documentType": "SSMDocument"
        },
        "name": "CreateFile",
        "timeoutSeconds": 300
      }
EOF
    },
  ]

  additional_ssm_bootstrap_step_count = "2"

  additional_tags = [
    {
      key                 = "MyTag1"
      value               = "Myvalue1"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag2"
      value               = "Myvalue2"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag3"
      value               = "Myvalue3"
      propagate_at_launch = true
    },
  ]

  encrypt_secondary_ebs_volume  = "False"
  asg_wait_for_capacity_timeout = "10m"
}

module "ec2_asg_windows_no_codedeploy_test" {
  source    = "../../module"
  ec2_os    = "windows2016"
  asg_count = "2"

  #  load_balancer_names                    = ["${aws_elb.my_elb.name}"]
  cw_low_operator = "LessThanThreshold"

  instance_role_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole",
    "arn:aws:iam::aws:policy/CloudWatchActionsEC2Access",
  ]

  instance_role_managed_policy_arn_count = "2"
  environment                            = "Development"
  ssm_association_refresh_rate           = "rate(1 day)"
  cw_scaling_metric                      = "CPUUtilization"
  enable_ebs_optimization                = "False"
  scaling_min                            = "1"
  cloudwatch_log_retention               = "30"
  secondary_ebs_volume_size              = "60"
  rackspace_managed                      = true
  cw_high_period                         = "60"
  enable_scaling_notification            = true
  subnets                                = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  secondary_ebs_volume_iops              = "0"
  ec2_scale_down_adjustment              = "1"
  cw_low_period                          = "300"
  key_pair                               = "CircleCI"
  tenancy                                = "default"
  backup_tag_value                       = "False"
  ec2_scale_down_cool_down               = "60"
  instance_type                          = "t2.micro"

  # If ALB target groups are being used, one can specify ARNs like the commented line below.
  #target_group_arns                      = ["${aws_lb_target_group.my_tg.arn}"]
  secondary_ebs_volume_type = "gp2"

  ec2_scale_up_adjustment    = "1"
  cw_high_threshold          = "60"
  scaling_notification_topic = "${module.sns_sqs.topic_arn}"
  cw_low_threshold           = "30"
  resource_name              = "${random_string.name_rstring.result}-ec2_asg_windows_no_codedeploy"
  ec2_scale_up_cool_down     = "60"
  ssm_patching_group         = "Group1Patching"
  health_check_grace_period  = "300"
  security_group_list        = ["${module.vpc.default_sg}"]
  perform_ssm_inventory_tag  = "True"
  terminated_instances       = "30"
  health_check_type          = "EC2"
  cw_low_evaluations         = "3"
  cw_high_evaluations        = "3"
  primary_ebs_volume_iops    = "0"
  detailed_monitoring        = "True"
  primary_ebs_volume_type    = "gp2"
  primary_ebs_volume_size    = "60"
  scaling_max                = "2"
  cw_high_operator           = "GreaterThanThreshold"
  install_codedeploy_agent   = "False"

  additional_ssm_bootstrap_list = [
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-Install_Datadog",
          "documentType": "SSMDocument"
        },
        "name": "InstallDataDog",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "AWS-RunPowerShellScript",
          "documentParameters": {
            "commands": ["echo $null >> C:\testfile"]
          },
          "documentType": "SSMDocument"
        },
        "name": "CreateFile",
        "timeoutSeconds": 300
      }
EOF
    },
  ]

  additional_ssm_bootstrap_step_count = "2"

  additional_tags = [
    {
      key                 = "MyTag1"
      value               = "Myvalue1"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag2"
      value               = "Myvalue2"
      propagate_at_launch = true
    },
    {
      key                 = "MyTag3"
      value               = "Myvalue3"
      propagate_at_launch = true
    },
  ]

  encrypt_secondary_ebs_volume  = "False"
  asg_wait_for_capacity_timeout = "10m"
}
