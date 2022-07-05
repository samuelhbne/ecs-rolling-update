provider "aws" {
  alias                     = "us_west_1"
  region                    = "us-east-1"
}

resource "aws_acm_certificate" "cert_domain" {
  provider                  = aws.us_west_1
  domain_name               = "${var.SERVICE_DOMAIN}.${var.DOMAIN}"
  //subject_alternative_names = [formatlist("%s.${var.DOMAIN}", keys(var.STACKS))]
  validation_method         = "DNS"
}

resource "aws_route53_record" "record_domain" {
  for_each = {
      for dvo in aws_acm_certificate.cert_domain.domain_validation_options : dvo.domain_name => {
      name                  = dvo.resource_record_name
      record                = dvo.resource_record_value
      type                  = dvo.resource_record_type
      }
  }

  allow_overwrite           = true
  name                      = each.value.name
  records                   = [each.value.record]
  ttl                       = 60
  type                      = each.value.type
  zone_id                   = data.aws_route53_zone.zone_domain_external.zone_id
}

resource "aws_acm_certificate_validation" "vld_domain" {
  for_each                  = var.STACKS
  provider                  = aws.us_west_1
  certificate_arn           = aws_acm_certificate.cert_domain.arn
  validation_record_fqdns   = [for record in aws_route53_record.record_domain : record.fqdn]
}
