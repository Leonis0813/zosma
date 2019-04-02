pipeline {
  agent any

  parameters {
    string(name: 'ZOSMA_BRANCH', defaultValue: null, description: 'デプロイするブランチ')
    string(name: 'SUBRA_BRANCH', defaultValue: 'master', description: 'Chefのブランチ')
    choice(name: 'SCOPE', choices: 'app\nfull', description: 'デプロイ範囲')
  }

  stages {
    stage('Clone Chef') {
      steps {
        git url: 'https://github.com/Leonis0813/subra.git', branch: params.SUBRA_BRANCH
      }
    }

    stage('Deploy') {
      steps {
        script {
          sh 'printenv'
          def version = (params.ZOSMA_BRANCH == null ? env.GIT_BRANCH : params.ZOSMA_BRANCH)
          def recipe = ('app' == params.SCOPE ? 'app' : 'default')
          sh "sudo ZOSMA_BRANCH=${version} chef-client -z -r zosma::${recipe} -E ${env.ENVIRONMENT}"
        }
      }
    }
  }
}
