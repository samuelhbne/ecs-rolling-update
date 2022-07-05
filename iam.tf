data "aws_iam_policy_document" "ecs_agent_policy_doc" {
  statement {
    actions             = ["sts:AssumeRole"]
     principals {
        type            = "Service"
        identifiers     = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name                  = "ecs-instance-role"
  assume_role_policy    = data.aws_iam_policy_document.ecs_agent_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role                  = aws_iam_role.ecs_instance_role.name
  policy_arn            = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role_profile" {
  name                  = "ecs-instance-role-profile"
  role                  = aws_iam_role.ecs_instance_role.name
}

