pipeline {
  agent any

  parameters {
    string(name: 'ZOSMA_VERSION', defaultValue: '', description: 'デプロイするバージョン')
    string(name: 'SUBRA_BRANCH', defaultValue: 'master', description: 'Chefのブランチ')
    choice(name: 'SCOPE', choices: 'app\nfull', description: 'デプロイ範囲')
  }

  stages {
    stage('Deploy') {
      steps {
        ws("${env.WORKSPACE}/../chef") {
          script {
            git url: 'https://github.com/Leonis0813/subra.git', branch: params.SUBRA_BRANCH
            def version = (params.ZOSMA_VERSION == '' ? env.GIT_BRANCH : params.ZOSMA_VERSION)
            version = version.replaceFirst(/^.+\//, '')
            def recipe = ('app' == params.SCOPE ? 'app' : 'default')
            sh "sudo ZOSMA_VERSION=${version} chef-client -z -r zosma::${recipe} -E ${env.ENVIRONMENT}"
          }
        }
      }
    }
  }
}
