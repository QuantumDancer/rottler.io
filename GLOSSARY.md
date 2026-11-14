# rottler.io

The personal website of Benjamin Rottler: a static site, and the
infrastructure that serves it.

## Language

### Hosts

**Canonical host**:
The one hostname the site is published under, `rottler.io`. Every other
public hostname for the site exists only to send visitors here.
_Avoid_: primary domain, main domain, apex (when the role is meant, not the
DNS position)

**Alternate host**:
A public hostname that answers for the site but is not the canonical host,
today only `www.rottler.io`. It never serves content of its own.
_Avoid_: secondary domain, mirror, alias (the CloudFront term, which also
covers the canonical host)
