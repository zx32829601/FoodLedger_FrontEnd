pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    parameters {
        booleanParam(
            name: 'RUN_LOCAL_DEPLOY',
            defaultValue: true,
            description: '驗證後使用 Docker Compose 部署到 Jenkins 主機。'
        )
        string(
            name: 'FOOD_LEDGER_API_BASE_URL',
            defaultValue: '',
            description: '選填的後端 API URL 覆寫值；留空時使用部署主機 .env。'
        )
        string(
            name: 'FOODLEDGER_WEB_HTTP_PORT',
            defaultValue: '8080',
            description: '前端容器對 Jenkins 主機公開的 HTTP 連接埠。'
        )
        string(
            name: 'FOODLEDGER_WEB_IMAGE',
            defaultValue: 'foodledger-web:jenkins',
            description: 'Jenkins 建置及部署使用的 Docker 映像名稱。'
        )
        string(
            name: 'DOCKER_CLI_BIN',
            defaultValue: 'C:\\Users\\zx328\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin',
            description: 'Jenkins 主機上 docker.exe 所在目錄。'
        )
    }

    environment {
        DOCKER_DESKTOP_MACHINE_BIN = 'C:\\Program Files\\Docker\\Docker\\resources\\bin'
        DOCKER_DESKTOP_USER_BIN = "${env.LOCALAPPDATA}\\Programs\\DockerDesktop\\resources\\bin"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Show Docker Versions') {
            steps {
                withEnv(["PATH=${params.DOCKER_CLI_BIN};${env.DOCKER_DESKTOP_MACHINE_BIN};${env.DOCKER_DESKTOP_USER_BIN};${env.PATH}"]) {
                    powershell 'docker --version'
                    powershell "& './scripts/Invoke-DockerCompose.ps1' -ArgumentList @('version')"
                }
            }
        }

        stage('Validate Docker Compose') {
            steps {
                script {
                    def composeEnvironment = [
                        "PATH=${params.DOCKER_CLI_BIN};${env.DOCKER_DESKTOP_MACHINE_BIN};${env.DOCKER_DESKTOP_USER_BIN};${env.PATH}",
                        "FOODLEDGER_WEB_HTTP_PORT=${params.FOODLEDGER_WEB_HTTP_PORT}",
                        "FOODLEDGER_WEB_IMAGE=${params.FOODLEDGER_WEB_IMAGE}"
                    ]

                    if (params.FOOD_LEDGER_API_BASE_URL?.trim()) {
                        composeEnvironment.add(
                            "FOOD_LEDGER_API_BASE_URL=${params.FOOD_LEDGER_API_BASE_URL.trim()}"
                        )
                    }

                    withEnv(composeEnvironment) {
                        powershell "& './scripts/Invoke-DockerCompose.ps1' -ArgumentList @('config', '--quiet')"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def composeEnvironment = [
                        "PATH=${params.DOCKER_CLI_BIN};${env.DOCKER_DESKTOP_MACHINE_BIN};${env.DOCKER_DESKTOP_USER_BIN};${env.PATH}",
                        "FOODLEDGER_WEB_HTTP_PORT=${params.FOODLEDGER_WEB_HTTP_PORT}",
                        "FOODLEDGER_WEB_IMAGE=${params.FOODLEDGER_WEB_IMAGE}"
                    ]

                    if (params.FOOD_LEDGER_API_BASE_URL?.trim()) {
                        composeEnvironment.add(
                            "FOOD_LEDGER_API_BASE_URL=${params.FOOD_LEDGER_API_BASE_URL.trim()}"
                        )
                    }

                    timeout(time: 30, unit: 'MINUTES') {
                        withEnv(composeEnvironment) {
                            powershell "& './scripts/Invoke-DockerCompose.ps1' -ArgumentList @('build', '--pull')"
                        }
                    }
                }
            }
        }

        stage('Deploy to Docker') {
            when {
                expression {
                    return params.RUN_LOCAL_DEPLOY
                }
            }
            steps {
                script {
                    def composeEnvironment = [
                        "PATH=${params.DOCKER_CLI_BIN};${env.DOCKER_DESKTOP_MACHINE_BIN};${env.DOCKER_DESKTOP_USER_BIN};${env.PATH}",
                        "FOODLEDGER_WEB_HTTP_PORT=${params.FOODLEDGER_WEB_HTTP_PORT}",
                        "FOODLEDGER_WEB_IMAGE=${params.FOODLEDGER_WEB_IMAGE}"
                    ]

                    if (params.FOOD_LEDGER_API_BASE_URL?.trim()) {
                        composeEnvironment.add(
                            "FOOD_LEDGER_API_BASE_URL=${params.FOOD_LEDGER_API_BASE_URL.trim()}"
                        )
                    }

                    timeout(time: 10, unit: 'MINUTES') {
                        withEnv(composeEnvironment) {
                            powershell "& './scripts/deploy-local.ps1' -SkipBuild"
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Frontend Jenkins pipeline completed successfully.'
        }
        failure {
            echo 'Frontend Jenkins pipeline failed. Check the stage logs for details.'
        }
    }
}
