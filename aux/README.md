##### WSL config
https://learn.microsoft.com/pt-br/windows/wsl/tutorials/wsl-vscode

wsl --install -d Ubuntu-26.04 
wsl -d Ubuntu-26.04

##### docker
https://dev.to/poveda/wsl2-podman-uma-alternativa-ao-docker-desktop-5cd6 

##### Spec Compiler
https://github.com/SpecIR/SpecCompiler

##### HDL
https://www.mathworks.com/help/hdlcoder/index.html
https://www.mathworks.com/help/hdlcoder/gs/fpga-synthesis-and-analysis-using-the-hdl-workflow-advisor.html
https://au.mathworks.com/help/hdlcoder/ug/matlab-hdl-coder-workflow-advisor.html

##### plantUML

https://plantuml.com/timing-diagram

```puml:label-whatever{caption=""}
@startuml
title Between 0-max (by default)
analog "Analog" as A

@0
A is 350

@100
A is 450

@300
A is 350
@enduml
```
