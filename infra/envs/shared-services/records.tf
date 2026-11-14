# ==============================================================================
# Records copied from the old zone
# ==============================================================================
#
# Everything in the management account's hand-managed zone that isn't the
# website's and isn't being dropped. Values, types and TTLs are copied
# verbatim; the cutover diffs this zone against the live one before the NS
# switch.
#
# Mail is aliased to the main mailbox at mailbox.org, so a mistake here loses
# mail silently. The DKIM names (`mbo000N._domainkey`) don't start with `_`,
# which keeps them out of the website-dns role's CNAME scope.

locals {
  copied_records = {
    mx = {
      name    = local.domain_name
      type    = "MX"
      ttl     = 3600
      records = ["10 mxext1.mailbox.org", "10 mxext2.mailbox.org", "20 mxext3.mailbox.org"]
    }
    spf = {
      name    = local.domain_name
      type    = "TXT"
      ttl     = 3600
      records = ["v=spf1 include:mailbox.org ~all"]
    }
    dmarc = {
      name    = "_dmarc.${local.domain_name}"
      type    = "TXT"
      ttl     = 400
      records = ["v=DMARC1;p=none;rua=mailto:postmaster@rottler.io"]
    }
    dkim_1 = {
      name    = "mbo0001._domainkey.${local.domain_name}"
      type    = "CNAME"
      ttl     = 3600
      records = ["MBO0001._domainkey.mailbox.org"]
    }
    dkim_2 = {
      name    = "mbo0002._domainkey.${local.domain_name}"
      type    = "CNAME"
      ttl     = 3600
      records = ["MBO0002._domainkey.mailbox.org"]
    }
    dkim_3 = {
      name    = "mbo0003._domainkey.${local.domain_name}"
      type    = "CNAME"
      ttl     = 3600
      records = ["MBO0003._domainkey.mailbox.org"]
    }
    dkim_4 = {
      name    = "mbo0004._domainkey.${local.domain_name}"
      type    = "CNAME"
      ttl     = 3600
      records = ["MBO0004._domainkey.mailbox.org"]
    }
    # Bluesky handle verification. Not mail, and easy to miss.
    atproto = {
      name    = "_atproto.${local.domain_name}"
      type    = "TXT"
      ttl     = 300
      records = ["did=did:plc:6i2sqknxz3lbddskgxavoj6p"]
    }
  }
}

resource "aws_route53_record" "copied" {
  for_each = local.copied_records

  zone_id = module.dns.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}
