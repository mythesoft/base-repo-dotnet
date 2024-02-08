import groovy.text.SimpleTemplateEngine   

podTemplate(
    
	name: 'dotnet-and-docker',
	label: "build",
	containers: [
        containerTemplate(name: 'dotnet',       image: 'mcr.microsoft.com/dotnet/sdk:7.0',ttyEnabled: true,command: 'cat'), 
		containerTemplate(name: 'kaniko',       image: 'gcr.io/kaniko-project/executor:debug', command: '/busybox/cat', ttyEnabled: true),
        containerTemplate(name: 'kubectl',      image: 'lachlanevenson/k8s-kubectl', ttyEnabled: true, command: 'cat'),
        containerTemplate(name: 'helm',         image: 'lachlanevenson/k8s-helm', command: 'cat', ttyEnabled: true)
    ],
	volumes: [
		emptyDirVolume(mountPath: '/var/lib/docker', memory: false),
		hostPathVolume(hostPath: '/var/run/crio/crio.sock', mountPath: '/var/run/crio/crio.sock')
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
                def props = readProperties file: '.ci/dev.env' 
                env.SERVICE = props.SERVICE
                env.RELEASE_NAME = props.RELEASE_NAME
                env.TAG = "ENV"
                env.BASE_REGISTRY = props.BASE_REGISTRY
                env.DOCKER_IMAGE_NAME = "${TEAM}/${PROJECT_BASE}"
                env.TIMEOUT = props.TIMEOUT
                env.REGISTRY_URI = props.REGISTRY_URI
                env.TEAM = props.TEAM
                env.PROJECT_BASE = props.PROJECT_BASE
                env.ROLE = props.ROLE
                env.SRV_NAME = "${PROJECT_BASE}-${ROLE}"
                env.REPO_BASE_URI = "${REGISTRY_URI}/${REPO_NAME}"
            }
        }

        stage('Restore dependencies') 
        {
            container('dotnet') 
            {
                sh 'dotnet --version'
                sh 'dotnet restore'
            }
        }

        stage('Build application') 
        {
            container('dotnet') 
            {
                sh 'dotnet build --no-restore'
            }
        }


        def gitCommit = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()

        stage('Building the image...') {
            container(name: 'kaniko', shell: '/busybox/sh') {
                withCredentials([usernamePassword(credentialsId: 'nexus-jenkins-id', passwordVariable: 'nexusPassword', usernameVariable: 'nexusUser')]) 
                {
                    sh """
                    cat <<EOF > /kaniko/.docker/config.json
                    {
                        "auths": {
                            "$BASE_REGISTRY": {
                                "username": "$nexusUser",
                                "password": "$nexusPassword"
                            }
                        },
                        "credHelpers": {
                            "eu.gcr.io": "gcr"
                        }
                    }
                    EOF
                    mkdir /workspace
                    """
                }
                
                withEnv(['PATH+EXTRA=/busybox:/kaniko']) {
                    sh """#!/busybox/sh
                    /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:${TAG}-${gitCommit}
                    """
                }
                
            }
        }

        def helmResourceType = 'Deployment'
        def helmResourceName = ''

        stage('Deploying app...') {
            container('helm') 
            {
                def stage = "DEV"
                def versionName = "${TAG}-${gitCommit}"
                def helmReleaseName = "${SERVICE}"
                def chartFolder = ".helm/chart"
                def helmFlags = "--values=.helm/chart/values-${stage}.yaml --namespace ${TEAM} --set image.repository=${BASE_REGISTRY}/${DOCKER_IMAGE_NAME} --set image.tag=${versionName} --set ingress.enabled=true --set ingress.hosts[0].host=yourhost.com, "

                sh "helm upgrade --install ${helmFlags} ${helmReleaseName} ${chartFolder}"
                helmResourceName = sh(returnStdout: true, script:
                    "helm template ${helmReleaseName} ${helmFlags} ${chartFolder} | " +
                            // Find deployment amongst all stuff rendered by helm
                            "awk '/${helmResourceType}/,/--/' | " +
                            // Find metadata and name
                            "awk '/metadata/,/  name:/' | " +
                            // grep only the "pure" name lines
                            "grep -e '^[ ]*name:' | " +
                            // keep only the first bellow metadata
                            "head -1 | " +
                            // keep only the value, drop "name:"
                            "sed 's@name:@@'")
                    // Get rid of whitespaces
                    .trim()
            }
        }

        stage('Waiting for the app to be ready...') {
            container('kubectl') {
                sh "kubectl rollout status ${helmResourceType} ${helmResourceName} --timeout=${TIMEOUT}"
            }
        }

    }
}

