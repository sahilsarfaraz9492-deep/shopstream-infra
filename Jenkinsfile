pipeline {
  agent any
  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Tick to destroy all AWS resources')
  }
  environment {
    AWS_DEFAULT_REGION    = 'us-east-1'
    AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Terraform Init') {
      steps { sh 'terraform init -input=false' }
    }
    stage('Format Check') {
      when { expression { !params.DESTROY } }
      steps { sh 'terraform fmt -check -recursive' }
      post {
        success { githubNotify context: 'tf/format', status: 'SUCCESS', description: 'Terraform formatting is clean' }
        failure { githubNotify context: 'tf/format', status: 'FAILURE', description: 'Run terraform fmt -recursive and push' }
      }
    }
    stage('Validate') {
      when { expression { !params.DESTROY } }
      steps { sh 'terraform validate' }
      post {
        success { githubNotify context: 'tf/validate', status: 'SUCCESS', description: 'Configuration is valid' }
        failure { githubNotify context: 'tf/validate', status: 'FAILURE', description: 'Terraform validate failed' }
      }
    }
    stage('Plan') {
      when { expression { !params.DESTROY } }
      steps { sh 'terraform plan -input=false -out=tfplan' }
      post {
        success { githubNotify context: 'tf/plan', status: 'SUCCESS', description: 'Plan created - see console for changes' }
        failure { githubNotify context: 'tf/plan', status: 'FAILURE', description: 'Terraform plan failed' }
      }
    }
    stage('Approval') {
      when { allOf { branch 'main'; expression { !params.DESTROY } } }
      steps { input message: 'Review the plan above. Apply to AWS?', ok: 'Apply' }
    }
    stage('Apply') {
      when { allOf { branch 'main'; expression { !params.DESTROY } } }
      steps { sh 'terraform apply -input=false tfplan' }
    }
    stage('Outputs') {
      when { allOf { branch 'main'; expression { !params.DESTROY } } }
      steps { sh 'terraform output' }
    }
    stage('Destroy Plan') {
      when { expression { params.DESTROY } }
      steps { sh 'terraform plan -destroy -input=false -out=tfdestroy' }
    }
    stage('Destroy Approval') {
      when { expression { params.DESTROY } }
      steps { input message: 'This DELETES the server, network and ECR repos. Continue?', ok: 'Destroy' }
    }
    stage('Destroy') {
      when { expression { params.DESTROY } }
      steps { sh 'terraform apply -input=false tfdestroy' }
    }
  }
  post {
    failure {
      withCredentials([string(credentialsId: 'discord-webhook', variable: 'DISCORD_URL')]) {
        sh '''
          curl -s -H "Content-Type: application/json" \
            -d "{\\"content\\":\\"INFRA BUILD FAILED: ${JOB_NAME} #${BUILD_NUMBER} - ${BUILD_URL}\\"}" \
            "$DISCORD_URL"
        '''
      }
    }
  }
}
