pipeline {
    agent any

    environment {
        DOCKER_REPO = 'achrefmessai/dockerapp1' // ton repo Docker Hub
        SKIP_TLS_VERIFY = 'true'                // garde true si tu utilises Docker Desktop ou Minikube
    }

    stages {

        stage('Préparer le tag') {
            steps {
                script {
                    def shortSha = 'nocmt'
                    try {
                        shortSha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    } catch (err) {
                        echo "Impossible d'obtenir le SHA git: ${err}"
                    }
                    env.IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}-${shortSha}"
                    env.FULL_IMAGE = "${env.DOCKER_REPO}:${env.IMAGE_TAG}"
                    echo "Image tag: ${env.FULL_IMAGE}"
                }
            }
        }

        stage('Construire l\'image Docker') {
            steps {
                script {
                    sh "docker build -t ${env.FULL_IMAGE} ."
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

        stage('Déployer sur Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                        script {
                            sh '''
                                echo "🔧 Vérification du cluster depuis Jenkins..."
                                kubectl config view --minify

                                echo "📝 Mise à jour de l'image dans le manifest..."
                                sed -E "s|(image: ).*|\\1${FULL_IMAGE}|" deployment.yaml > deployment-merged.yaml || cp deployment.yaml deployment-merged.yaml

                                echo "🚀 Déploiement sur Kubernetes..."
                                kubectl apply -f deployment-merged.yaml
                                kubectl apply -f service.yaml

                                echo "✅ Déploiement terminé sur le cluster :"
                                kubectl get pods -o wide
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline terminé avec succès. Image déployée : ${env.FULL_IMAGE}"
        }
        failure {
            echo "❌ Pipeline échoué. Vérifiez les logs de Jenkins."
        }
    }
}
