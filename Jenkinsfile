import groovy.text.SimpleTemplateEngine   

podTemplate(
    
	name: 'dotnet-and-docker',
	label: "build",
	containers: [
        containerTemplate(name: 'dotnet',       image: 'mcr.microsoft.com/dotnet/sdk:7.0',ttyEnabled: true,command: 'cat'), 
		containerTemplate(name: 'kaniko',       image: 'gcr.io/kaniko-project/executor:latest', command: 'cat', ttyEnabled: true),
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
                def props = readProperties file: '.ci/DEV.env' 
                env.SERVICE = props.service
                env.RELEASE_NAME = props.service
                env.TAG = "ENV"
                env.BASE_REGISTRY = "repository.labs.itellyou.ca:8182"
                env.DOCKER_IMAGE_NAME = props.service
                env.TIMEOUT = "2m"
                env.REGISTRY_URI = "repository.labs.itellyou.ca:8182"
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
            container('kaniko') {
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
                    """
                }
                
                sh "/kaniko/executor -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}\${TAG}-${gitCommit}"
            }
        }

        stage('Building the image...') 
        {
            container('docker')
            {
                sh 'docker --version'
                sh """
                docker build -t ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:\${TAG}-${gitCommit} .
                docker tag ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:\${TAG}-${gitCommit} \
                            ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:latest
                docker tag ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:\${TAG}-${gitCommit} \
                            ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:qa-${gitCommit}
                """
            }
        }

        stage('Cleaning dangling images...') {
            container('docker') {
                sh 'docker images --quiet --filter=dangling=true | xargs --no-run-if-empty docker rmi -f || true'
            }
        }

        stage('Pushing to registry...') {
            container('docker') {

                withCredentials([usernamePassword(credentialsId: 'nexus-jenkins-id', passwordVariable: 'nexusPassword', usernameVariable: 'nexusUser')]) 
                {
                    sh "docker login ${REGISTRY_URI} -u ${nexusUser} -p ${nexusPassword}"
                    sh """
                        docker push ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:\${TAG}-${gitCommit}
                        docker push ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:latest
                        docker push ${BASE_REGISTRY}/${DOCKER_IMAGE_NAME}:qa-${gitCommit}
                    """
                }
            }
        }

        def helmResourceType = 'Deployment'
        def helmResourceName = ''

        stage('Deploying app...') {
            container('helm') 
            {
                def stage = ""
                def versionName = "${TAG}-${gitCommit}"
                def helmReleaseName = "${SERVICE}"
                def chartFolder = ".helm/chart"
                def helmFlags = "--values=.helm/chart/values-${stage}.yaml --set image.repository=${BASE_REGISTRY}/${DOCKER_IMAGE_NAME} --set image.tag=${versionName}"

                sh "helm upgrade --install ${helmFlags} ${helmReleaseName} ${chartFolder}"
                helmResourceName = sh(returnStdout: true, script:
                    "helm template ${helmReleaseName} ${helmFlags} ${chartFolder} | " +
                            // Find deployment amongst all stuff rendered by helm
                            "awk '/${resource}/,/--/' | " +
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

