# one-filers
Like cool one-liners, but with files, but for terraform

I always have difficulties when I begin writing READMEs so I asked mister G. Pitee to write
a beginning for me. The code and the rest are my own.

# 🤠 Terraform Rodeo: AWS Edition 🤠

Howdy, partner! This here repo wrangles up yer AWS infrastructure 
using the mighty power of Terraform.  
We got VPCs, EC2s, and them fancy S3 buckets—all tamed and branded.  
Spin up yer cloud like a true cloud cowboy, one `terraform apply` at a time.  
Ain’t our first rodeo—modules, variables, and state files all neatly fenced in.  
Fork it, clone it, ride it into the sunset.  
Yeehaw and happy provisioning! 🌵🐎  

What?
-----
As perfectly summarised above, this repository contains terraform modules for ~~AWS~~ "AWS and more" resources.
Instead of using multiple files for each module, I plan to use one file that encompasses everything
for each use case. It is rather unconventional, but it helps me to organize based on the usage and not having to 
constantly look back and forth between files.

This is not practical or sane for large deployments, but it is practical when i want to experiment.

[very-important-bucket](very-important-bucket/README.md)

[re-re-recreate-nexus](re-re-recreate-nexus/README.md)
