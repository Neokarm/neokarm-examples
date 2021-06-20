# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#       
#          * 1 Instance
#          * 2 SNS topics
#          * Cloudwatch matic alarm
#
#  
#     This example was tested on versions:
#     - zCompute version 5.5.3
#     - terraform 0.12.27 & 0.13
# ---------------------------------------------------------------------------------------------------------------------



# Create X instances, and name them according to count
resource "aws_instance" "myapp_instance" {
  ami           = var.aws_ami
  instance_type = var.instance_type
  count         = var.instance_count
  tags = {
    Name = "instance_${count.index}"
  }
  # Can use any aws instance type supported by zCompute
}

resource "aws_sns_topic" "topic_name" {
  count = "2"
  name  = "${var.sns_topic_name_prefix}${count.index}"

  lifecycle {
    ignore_changes = ["display_name", "delivery_policy"]
  }
}

# Creating cloudwatch alarm
resource "aws_cloudwatch_metric_alarm" "alarm" {
  count               = var.instance_count
  alarm_name          = "${var.cloudwatch_alarm_prefix}${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    InstanceId = "${element(aws_instance.myapp_instance.*.id, count.index)}"
  }

  alarm_description         = "This metric monitors insufficient data on ${element(aws_instance.myapp_instance.*.id, count.index)}"
  insufficient_data_actions = ["${aws_sns_topic.topic_name.*.arn[0]}", "${aws_sns_topic.topic_name.*.arn[1]}"]
  ok_actions                = ["${aws_sns_topic.topic_name.*.arn[0]}", "${aws_sns_topic.topic_name.*.arn[1]}"]
  #alarm_actions                  = ["${aws_sns_topic.topic_name.*.arn[0]}"]    
}


resource "null_resource" "subscribe" {
  count = 2
  triggers = {
    topics = "${element(aws_sns_topic.topic_name.*.arn, count.index)}"
    ak     = var.access_key
    sk     = var.secret_key
    ip     = var.zCompute_ip

  }
  provisioner "local-exec" {
    command     = "python subscribe.py ${element(aws_sns_topic.topic_name.*.arn, count.index)} ${var.access_key} ${var.secret_key} ${var.zCompute_ip}"
    working_dir = "./boto/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "python unsubscribe.py '${self.triggers.topics}' '${self.triggers.ak}' '${self.triggers.sk}' '${self.triggers.ip}'"

    working_dir = "./boto/"
  }
}
