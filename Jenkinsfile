podTemplate(
	name: 'dotnet-and-docker',
	label: "build",
	containers: [
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
        stage('checkout') 
        {
            checkout scm
        }

        

        stage('Test enviroment') 
        {
            script {
                def props = readProperties file: '.env' 
                env.service = props.service
                env.servicePath = props.servicePath
                env.label = props.label
                env.version = props.version
            }
            println "In service: '${service}'"
            println "In servicePath: '${env.servicePath}'"
            println "In label: '${env.label}'"
            println "In version: '${version}'"
        }

        stage('Build image') 
        {
            container('dotnet') 
            {
                // opt out dotnet telemetry
                sh 'dotnet --version'
            }
        }

        stage('Build image') {
            container('docker') 
            {
                // opt out dotnet telemetry
                sh 'docker --version'
            }
        }

        stage('Push image to Docker Registry')
        {
            container('kubectl') 
            {
                // opt out dotnet telemetry
                sh 'kubectl get nodes'
            }
        }

    }
}