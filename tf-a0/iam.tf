resource "aws_iam_group" "tf-devops-1" {
  name = "tf-devops-1"
}

resource "aws_iam_user" "tf-user" {
  count = 3
  name = "tf-user-${count.index + 1}"
}

resource "aws_iam_user_group_membership" "tf-user-group-membership" {
  count = 3
  user  = aws_iam_user.tf-user[count.index].name
  groups = [
    aws_iam_group.tf-devops-1.name,
  ]
}

data "aws_iam_policy_document" "ec2-read-only-policy" {
  statement {
    actions = [
      "ec2:Describe*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ec2-read-only-policy" {
  name   = "ec2-read-only-policy"
  policy = data.aws_iam_policy_document.ec2-read-only-policy.json
}

resource "aws_iam_policy_attachment" "ec2-read-only-policy-attachment" {
  name       = "ec2-read-only-policy-attachment"
  policy_arn = aws_iam_policy.ec2-read-only-policy.arn
  groups     = [
    aws_iam_group.tf-devops-1.name
  ]
}