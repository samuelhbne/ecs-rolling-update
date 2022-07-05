/** 
Route53 hosted zone must be created manually to avoid potential conflicts with existing 
manual resource. Also, Terraforming hosted zone may resulted in duplicated zones if a 
hosted zone with same domain name already existed.

Please ensure the registed domain name-servers has been pointed correctly according to
the nameserver recorders in the Route53 hosted zone. You can do it manually following
the instruction below:

1. Get the Route53 hosted zone ID
$ aws route53 list-hosted-zones-by-name|jq '.HostedZones[] | select(.Name=="your-domain.com.") | .Id' | tr -d \" | cut -d '/' -f3
Z08729171NK8D2ZS3NVA9

2. Get the NS recorders of the Route53 hosted zone
$ aws route53 list-resource-record-sets --hosted-zone-id Z08729171NK8D2ZS3NVA9 \
      | jq '.ResourceRecordSets[] | select(.Type=="NS") | .ResourceRecords[].Value' \
      | sed 's/\"//g'|sed 's/.$//g' | awk '{print "Name="$1" "}' | tr -d '\n'
Name=ns-157.awsdns-19.com Name=ns-1952.awsdns-52.co.uk Name=ns-1223.awsdns-24.org Name=ns-617.awsdns-13.net

3. Update the registed domain name-servers according to the results you got.
$ aws route53domains update-domain-nameservers --region us-east-1 --domain-name your-domain.com --nameservers Name=ns-157.awsdns-19.com Name=ns-1952.awsdns-52.co.uk Name=ns-1223.awsdns-24.org Name=ns-617.awsdns-13.net

NOTE: DO NOT change the region option above, which was compulsory per route53domains
service's request.
*/

data "aws_route53_zone" "zone_domain_external" {
  name                      = var.DOMAIN
  private_zone              = false
}

/*
resource "null_resource" "updatens-domain" {
  provisioner "local-exec" {
    command                 = "aws route53domains update-domain-nameservers --region us-east-1 --domain-name ${var.domains["name"]} --nameservers Name=${aws_route53_zone.zone_domain_external.name_servers.0} Name=${aws_route53_zone.zone_domain_external.name_servers.1} Name=${aws_route53_zone.zone_domain_external.name_servers.2} Name=${aws_route53_zone.zone_domain_external.name_servers.3}"
    environment = {
      AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_ACCESS_KEY
    }    
  }
}
*/