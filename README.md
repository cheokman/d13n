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
* Jenkinsfile
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
Generating Rake file ...
Generating Rake Task folder ...
Generating database migration folders ...
Generating Rake migration file ...
Generating Gemfile ...
Generating Makefile ...
Generating test.yml ...
Generating docker folder ...
Generating docker development folder ...
Generating development docker files ...
Generating docker release folder ...
Generating release docker files ...
Generating docker scripts ...
Generating Jekinsfile ...
Generating Ruby Version file ...
Generating RSpec configuraion file ...
Generating Spec folders ...
Generating Rspec Helper file ...
Generating Rspec rake task file ...
```

Above is to generate a project named g2 and application piston.

Run Docker Test Step

```bash
cd piston
make test
```

## Library Scaffold

For library, d13n privods a bare option to scaffold some files and folders, which can help to speed up the library development with docker ready on CI testing.

### How to use 

Assume an library named pivot-api with empty folder

```
mkdir pivot-api
cd pivot-api

git init .
git remote add origin http://ben.wu@stash.mo.laxino.com/scm/g2/pivot-api.git
```

After git repository create and add origin path, next to use d13n to scaffold a library folders and files

```
d13n scaffold -a pivot-api -p g2 --bare
Generating Rake file ...
Generating Rake Task folder ...
Generating database migration folders ...
Generating Rake migration file ...
Generating Gemfile ...
Generating Makefile ...
Generating pivot-api.yml ...
Generating docker folder ...
Generating docker development folder ...
Generating development docker files ...
Generating docker release folder ...
Generating release docker files ...
Generating docker scripts ...
Generating Jekinsfile ...
Generating Ruby Version file ...
Generating RSpec configuraion file ...
Generating Spec folders ...
Generating Rspec Helper file ...
Generating Rspec rake task file ...
```

Above folder and files will be generated

```
git add .
git commit -m 'first init'
git push origin master
```

## Developement Stage to build gem

* checkout the master
* build gem with gemspec file
* install gem locally

```bash
git clone http://{your name}@stash.mo.laxino.com/scm/~ben.wu/d13n.git
cd d13n
gem build d13n.gemspec
gem install -l d13n-{version}.gem
```
