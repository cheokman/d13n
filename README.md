# Dockerization Gem for Microservice

To reduce developer afford to apply docker techinology for Microserice, d13n gem privodes following features:

* Microservice Scaffold
* Configuration Management
* Log Management
* Metric Collection
* Alert and Monitor

d13n provides a executable command 'd13n' and some sub-commands to cater all freatures

## Microservice Scaffold

To lower the barrier for developer bootstrap a docker compactable Microserivce application, d13n provides scaffold feature to boostrap Microservice application folder in:

* CI Build and Release Docker files and scripts
* CI Workflow Makefile 
* DB Migration folder
* Jenkinefiles 
* Application Configuration YAML file

### How to Use

d13n sub-command 'scaffold' will provide scaffold feature with minimun required options

Here is the help of scaffold:

```bash
Usage: d13n scaffold [OPTIONS] ["description"]

Specific options:
    -a, --app APP                            Specify an application to scaffold
    -p, --project PROJECT                    Specify project of application to scaffold
    -b, --bare                               Scaffold a bare folder
```

The required options of scaffold are application name and project name belonged to application

Example:

```bash
d13n scaffold -p g2 -a piston
Setting up appication [Piston] directories...
Generating database migration folders ...
Generating Makefile ...
Generating piston.yaml ...
Generating docker folder ...
Generating docker development folder ...
Generating development docker files ...
Generating docker release folder ...
Generating release docker files ...
Generating docker scripts ...
Generating Jekinsfile ...
```

Above is to generate a project named g2 and application piston.

## Developement Stage to build gem

* checkout the master
* build gem with gemspec file
* install gem locally

```bash
git http://{your name}@stash.mo.laxino.com/scm/~ben.wu/d13n.git
cd d13n
gem build d13n.gemspec
gem install -l d13n-{version}.gem
```
