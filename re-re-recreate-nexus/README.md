A Very Important Bucket
---

#### Prerequisites

This was executed against a **Sonatype Nexus Repository Community Edition (CE) v3.81.1-01**.
 Your experience may vary.

**This procedure assumes** that the Nexus repository VM exists and also that **the api is accessible
through https**. Personally **I have set up a Nexus behind a Traefik** that acts as a reverse proxy
so that I can have Let's Encrypt TLS and finally avoid having to specify a port other than the default 443. 

### Proxying

The Traefik configuration is beyond the scope of this project but I will include the specific configuration that works
just for reference. You can always set up nexus as is and access it and its registries through the various ports without 
reverse proxying.

In my case Traefik is responsible for the TLS using Let's Encrypt.

```yaml
http:

  routers:
    nexus-https:
      rule: "Host(`nexus.domai.in`)"
      service: nexus-service
      entrypoints:
        - websecure
      tls:
        certresolver: "letsencrypt"
    nexus-http:
      rule: "Host(`nexus.domai.in`)"
      service: nexus-service
      entrypoints:
        - web
      middlewares:
        - https-redirect

    registry-2-https:
      rule: "Host(`registry-2.domai.in`)"
      service: registry-2-service
      entrypoints:
        - websecure
      tls:
        certresolver: "letsencrypt"
    registry-2-http:
      rule: "Host(`registry-2.domai.in`)"
      service: registry-2-service
      entrypoints:
        - web
      middlewares:
        - https-redirect

    registry-internal-https:
      rule: "Host(`registry-3.domai.in`)"
      service: registry-internal-service
      entrypoints:
        - websecure
      tls:
        certresolver: "letsencrypt"
    registry-internal-http:
      rule: "Host(`registry-3.domai.in`)"
      service: registry-internal-service
      entrypoints:
        - web
      middlewares:
        - https-redirect

  services:
    nexus-service:
      loadBalancer:
        servers:
        - url: "http://10.0.0.4:8081/"

    registry-2-service:
      loadBalancer:
        servers:
        - url: "http://10.0.0.5:8084"

    registry-internal-service:
      loadBalancer:
        servers:
        - url: "http://10.0.0.6:8082"

  middlewares:
    https-redirect:
      redirectScheme:
        scheme: https
```

**I am using different domain names for the various docker registries** in order to circumvent 
using subdomains for the docker registries.

### Getting started

**This module can be run directly after Sonatype Nexus is initialized**. The **initial admin password**, 
can be used directly **without the need of changing it**. This helps if you want to parameterize Nexus
with minimal interaction, and then change the admin password after everything is donw.

The **initial admin password** is usually located under:

```/opt/sonatype-work/nexus3/admin.password``` 

**until the first login**, during which you are prompted to change it.

### Plain text passwords

In the ```nexus.tf``` file, the **password for Nexus is in plain text for reference**. This should be treated as a secret
and stored accordingly but this is just a proof of concept so in this case, it is irrelevant.
