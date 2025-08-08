output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
  
}

output "alb_security_group_id" {
  description = "The ID of the security group for the Application Load Balancer"
  value = aws_security_group.alb.id
}