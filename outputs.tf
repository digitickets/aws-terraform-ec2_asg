output "asg_name_list" {
  description = "List of ASG names"
  value       = ["${aws_autoscaling_group.autoscalegrp.*.name}"]
}

output "iam_role" {
  description = "Name of the created IAM Instance role."
  value       = "${element(coalescelist(aws_iam_role.mod_ec2_instance_role.*.id, list("none")), 0)}"
}

output "asg_image_id" {
  description = "Image ID used for EC2 provisioning"
  value       = "${var.image_id != "" ? var.image_id : data.aws_ami.asg_ami.image_id}"
}

output "asg_scale_up_policy_arns" {
  description = "List of scale up policy arns to allow external couldwatch alarms to trigger scale up"
  value = ["${aws_autoscaling_policy.ec2_scale_up_policy.*.arn}"]
}

output "asg_scale_down_policy_arns" {
  description = "List of scale down policy arns to allow external couldwatch alarms to trigger scale down"
  value = ["${aws_autoscaling_policy.ec2_scale_down_policy.*.arn}"]
}
