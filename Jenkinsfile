podTemplate(
	name: 'dotnet-and-docker',
	label: "build",
	containers: [
        containerTemplate(name: 'jnlp',         image: 'jenkinsci/jnlp-slave:alpine'),
		containerTemplate(name: 'dotnet',       image: 'mcr.microsoft.com/dotnet/sdk:7.0',ttyEnabled: true,command: 'cat'), 
		containerTemplate(name: 'docker',       image: 'docker:stable-dind', ttyEnabled: true, command: 'cat', privileged: true),
        containerTemplate(name: 'kubectl',      image: 'lachlanevenson/k8s-kubectl', ttyEnabled: true, command: 'cat'),
    ],
	volumes: [
		emptyDirVolume(mountPath: '/var/lib/docker', memory: false),
		hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')
	]		
)
{
	node("build") 
    {
        container('dotnet') 
        {
            // opt out dotnet telemetry
            sh 'dotnet --version'
        }

        container('docker') 
        {
            // opt out dotnet telemetry
            sh 'docker --version'
        }

        container('kubectl') 
        {
            // opt out dotnet telemetry
            sh 'kubectl get nodes'
        }

    }
}