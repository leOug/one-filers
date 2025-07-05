A Very Important Bucket
---

#### Prerequisites

This was executed against a **Sonatype Nexus Repository Community Edition (CE) v3.81.1-01**.
 Your experience may vary.

**This procedure assumes** that the Nexus repository VM exists and also that **the api is accessible
through https**. Personally **I have set up a Nexus behind a Traefik** that acts as a reverse proxy
so that I can have Let's Encrypt TLS and finally avoid having to specify a port other than the default 443. 

The Traefik configuration is beyond the scope of this project. You can always set up nexus as is and
access it and its registries through the various ports without reverse proxying.

#### Getting started

**This module can be run directly after Sonatype Nexus is initialized**. The **initial admin password**, 
can be used directly **without the need of changing it**. This helps if you want to parameterize Nexus
with minimal interaction, and then change the admin password after everything is donw.

The **initial admin password** is usually located under:

```/opt/sonatype-work/nexus3/admin.password``` 

**until the first login**, during which you are prompted to change it.

#### Plain text password

In the ```nexus.tf``` file, the password for Nexus is in plain text for reference. This should be treated as a secret
and stored accordingly but this is just a proof of concept so in this case, it is irrelevant.
