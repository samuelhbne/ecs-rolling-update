data "aws_elb_service_account" "lb_svc_acc" {}

resource "aws_s3_bucket" "bkt_logs_lb" {
  for_each          = var.STACKS
  bucket            = "${var.ENV}-logs-lb-${each.key}"

  tags = {
    Name            = "${var.ENV}-logs-lb-${each.key}"
    Environment     = "${var.ENV}"
  }
}

resource "aws_s3_bucket_policy" "s3_policy_allow_elb" {
  for_each          = var.STACKS
  bucket            = aws_s3_bucket.bkt_logs_lb[each.key].id
  policy            = data.aws_iam_policy_document.s3_policy_doc_allow_elb[each.key].json
}

data "aws_iam_policy_document" "s3_policy_doc_allow_elb" {
  for_each          = var.STACKS
  statement {
    principals {
      type          = "AWS"
      identifiers   = ["${data.aws_elb_service_account.lb_svc_acc.arn}"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.bkt_logs_lb[each.key].arn,
      "${aws_s3_bucket.bkt_logs_lb[each.key].arn}/*",
    ]
  }
}
