# prj-doccomp-nginx-scale

//Jenkins 내부에 kubectl, kubeadm, kubelet 설치하고, 로컬 시스템의 ./kube/config 도 복사해 두었야 함.

# Jenkins - Kubernetes pipeline example
stage('Deploy to Kubernetes') {
    try {
        sh(script: 'kubectl apply -f nginxscale-k8s-deploy.yml app=mkbahk/nginxscale:latest')
    } catch(e) {
        echo "nginxweb service exists"
    }
    sh(script: 'kubectl set image -f nginxscale-k8s-deploy.yml app=mkbahk/nginxscale:0.${BUILD_NUMBER}')
}


    script {
        kubernetesDeploy(configs: "nginxscale-k8s-deploy.yaml", kubeconfigId: "srv161")
    }


node {
  stage('Apply Kubernetes files') {
    withKubeConfig([credentialsId: 'jenkins-deployer', serverUrl: 'https://192.168.64.2:8443']) {
      sh 'kubectl apply -f '
    }
  }
}

# Jenkins - Kubernetes Full pipeline
node {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER_ID', passwordVariable: 'DOCKER_USER_PASSWORD']]) {
        stage('Git Pull') {
            git 'https://github.com/mkbahk/nginxscale.git'
        }
        stage('Unit Test') {
    	    try  {
    	        sh(script: 'docker image rm mkbahk/nginxscale:latest')  
            } 
            catch(e) {
                echo "No nginxscale container to remove"
            }
        }
        stage('Docker Image Build') {
            sh(script: 'docker build --force-rm=true -t mkbahk/nginxscale:latest .')    
        }
        stage('Update Tag') {
            sh(script: 'docker tag ${DOCKER_USER_ID}/nginxscale:latest ${DOCKER_USER_ID}/nginxscale:0.${BUILD_NUMBER}')
        }
        stage('Push to Dockerhub.com/mkbahk/nginxscale:0.XX') {
            sh(script: 'docker login -u ${DOCKER_USER_ID} -p ${DOCKER_USER_PASSWORD}')
            sh(script: 'docker push ${DOCKER_USER_ID}/nginxscale:0.${BUILD_NUMBER}')
            sh(script: 'docker push ${DOCKER_USER_ID}/nginxscale:latest')
        }
        stage('Deploy to Kubernetes') {
            try {
                sh(script: 'kubectl apply -f https://raw.githubusercontent.com/mkbahk/nginxscale/master/nginxscale-k8s-deploy.yaml')
                sh(script: 'kubectl apply -f https://raw.githubusercontent.com/mkbahk/nginxscale/master/nginxscale-k8s-service.yaml')
            } catch(e) {
                echo "nginxscale service exists"
            }
            sh(script: 'kubectl set image -f https://raw.githubusercontent.com/mkbahk/nginxscale/master/nginxscale-k8s-deploy.yaml nginxscale-container=mkbahk/nginxscale:0.${BUILD_NUMBER}')
        }
    }
}



# Jenkins - Basic Stage
node {
	stage('Pull') {
	}
	stage('Unit Test') {
	}
	stage('Build') {
	}
	stage('Tag') {
	}
	stage('Push') {
	}
	stage('Deploy') {
	}
}

# Jenkins - Docker Cmd
node {
    stage('Git Pull') {
        git 'https://github.com/mkbahk/nginxscale.git'
    }
    stage('Unit Test') {
        try {
            sh(script: 'docker image rm mkbahk/nginxscale:latest')  
        } 
        catch(e) {
            echo "No nginxscale container to remove"
        }
    }
    stage('Docker Build') {
        sh(script: 'docker build --force-rm=true -t mkbahk/nginxscale:latest .')    
    }
    stage('Change Tag') {
        sh(script: 'docker tag mkbahk/nginxscale:latest mkbahk/nginxscale:2.1')
    }
    stage('Push to Dockerhub') {
        sh(script: 'docker login -u mkbahk -p "암호여기에입력필요"' )
        sh(script: 'docker push mkbahk/nginxscale:2.1' )
        sh(script: 'docker push mkbahk/nginxscale:latest' )
    }
    stage('Deploy as a Service') {
        try {
            sh(script: 'docker stop nginxscale')
            sh(script: 'docker rm nginxscale')
        } catch(e) {
            echo "No nginxscale container exists"
        }
        sh(script: 'docker run -d -p 8380:80 --name=nginxscale mkbahk/nginxscale:latest')
    }
}

# Jenkins - Docker Swarm Deploy
node {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER_ID', passwordVariable: 'DOCKER_USER_PASSWORD']]) {
        stage('Pull') {
            git 'https://github.com/mkbahk/nginxscale.git'
        }
        stage('Unit Test') {
    	    try  {
    	        sh(script: 'docker image rm mkbahk/nginxscale:latest')  
            } 
            catch(e) {
                echo "No nginxscale container to remove"
            }
        }
        stage('Build') {
            sh(script: 'docker build --force-rm=true -t mkbahk/nginxscale:latest .')    
        }
        stage('Tag') {
            sh(script: 'docker tag ${DOCKER_USER_ID}/nginxscale:latest ${DOCKER_USER_ID}/nginxscale:0.${BUILD_NUMBER}')
        }
        stage('Push') {
            sh(script: 'docker login -u ${DOCKER_USER_ID} -p ${DOCKER_USER_PASSWORD}')
            sh(script: 'docker push ${DOCKER_USER_ID}/nginxscale:0.${BUILD_NUMBER}')
            sh(script: 'docker push ${DOCKER_USER_ID}/nginxscale:latest')
        }
        stage('Deploy') {
            try {
                sh(script: 'docker service create --name nginxweb --publish 8380:80 --replicas 3 mkbahk/nginxscale:0.${BUILD_NUMBER}')
            } catch(e) {
                echo "nginxweb service exists"
            }
            sh(script: 'docker service update --image=mkbahk/nginxscale:0.${BUILD_NUMBER} nginxweb')
        }
    }
}

# Jenkins - Env. 활용
node {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER_ID', passwordVariable: 'DOCKER_USER_PASSWORD']]) {
        stage('Pull') {
            git 'https://github.com/mkbahk/nginxscale.git'
        }
        stage('Unit Test') {
    	    try  {
    	        sh(script: 'docker image rm mkbahk/nginxscale:latest')  
            } 
            catch(e) {
                echo "No nginxscale container to remove"
            }
        }
        stage('Build') {
            sh(script: 'docker build --force-rm=true -t mkbahk/nginxscale:latest .')    
        }
        stage('Tag') {
            sh(script: 'docker tag ${DOCKER_USER_ID}/nginxscale:latest ${DOCKER_USER_ID}/nginxscale:0.${BUILD_NUMBER}')
        }
        stage('Push') {
            sh(script: 'docker login -u ${DOCKER_USER_ID} -p ${DOCKER_USER_PASSWORD}')
            sh(script: 'docker push ${DOCKER_USER_ID}/nginxscale:0.${BUILD_NUMBER}')
            sh(script: 'docker push ${DOCKER_USER_ID}/nginxscale:latest')
        }
        stage('Deploy') {
            try {
                sh(script: 'docker stop nginxscale')
                sh(script: 'docker rm nginxscale')
            } catch(e) {
                echo "No nginxscale container exists"
            }
            sh(script: 'docker run -d -p 8380:80 --name=nginxscale ${DOCKER_USER_ID}/nginxscale:0.${BUILD_NUMBER}')
        }
    }
}