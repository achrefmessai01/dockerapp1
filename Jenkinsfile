pipeline {
    agent any

    environment {
        DOCKER_REPO = 'achrefmessai/dockerapp1'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${DOCKER_REPO}:${IMAGE_TAG}"
        HELM_CHART_PATH = './mon-app'
    }

    stages {
        stage('Préparer le code') {
            steps {
                checkout scm
                echo "✅ Dépôt cloné avec succès."
            }
        }

        stage('Construire l\'image Docker') {
            steps {
                script {
                    sh "docker build -t ${FULL_IMAGE} ."
                }
            }
        }

        stage('Pousser l\'image Docker') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockercred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker push ${FULL_IMAGE}
                        docker logout
                    '''
                }
            }
        }

        stage('Déployer avec Helm') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                        script {
                            // Met à jour l’image dans Helm via --set
                            sh """
                                helm upgrade --install mon-app ${HELM_CHART_PATH} \
                                --set image.repository=${DOCKER_REPO} \
                                --set image.tag=${IMAGE_TAG} \
                                --set image.pullPolicy=IfNotPresent \
                                --namespace default \
                                --create-namespace
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline terminé avec succès. Déployé avec Helm : ${FULL_IMAGE}"
        }
        failure {
            echo "❌ Pipeline échoué. Vérifie les logs Jenkins."
        }
    }
}
