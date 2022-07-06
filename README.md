# prj-doccomp-nginx-scale

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

